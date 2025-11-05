// Wait for the DOM to be fully loaded before running the script
document.addEventListener('DOMContentLoaded', () => {

  const canvas = document.getElementById('whiteboard-canvas');
  // Exit if the canvas isn't on this page
  if (!canvas) {
    return;
  }

  const ctx = canvas.getContext('2d');
  
  // Read data from the canvas element's 'data-' attributes
  const lobbyId = canvas.dataset.lobbyId;
  const canDraw = (canvas.dataset.canDraw === 'true');

  let currentTool = 'pencil';
  let isDrawing = false;
  let currentColor = '#000000';
  let currentSize = 3;
  let lastX = 0;
  let lastY = 0;
  let paths = []; // Store all drawing paths
  let isReceivingUpdate = false; // Prevent feedback loops

  // Get correct mouse position accounting for canvas scaling
  function getMousePos(e) {
    const rect = canvas.getBoundingClientRect();
    const scaleX = canvas.width / rect.width;
    const scaleY = canvas.height / rect.height;
    return {
      x: (e.clientX - rect.left) * scaleX,
      y: (e.clientY - rect.top) * scaleY
    };
  }

  // Tool selection
  document.getElementById('pencil-tool').onclick = () => selectTool('pencil');
  document.getElementById('clear-btn').onclick = clearCanvas;

  document.getElementById('color-picker').onchange = (e) => {
    currentColor = e.target.value;
    if (currentTool === 'eraser') selectTool('pencil');
  };

  document.getElementById('brush-size').oninput = (e) => {
    currentSize = parseInt(e.target.value);
    document.getElementById('size-display').textContent = currentSize;
  };

  function selectTool(tool) {
    currentTool = tool;
    document.querySelectorAll('.tool-btn').forEach(btn => btn.classList.remove('active'));
    document.getElementById(tool + '-tool').classList.add('active');
    canvas.style.cursor = canDraw ? 'crosshair' : 'not-allowed';
  }

  function clearCanvas() {
    if (confirm('Clear whiteboard? This will clear it for everyone in the lobby.')) {
      ctx.clearRect(0, 0, canvas.width, canvas.height);
      paths = [];
      saveToServer();
    }
  }

  // Drawing functions
  function startDrawing(e) {
    if (!canDraw) return;
    isDrawing = true;
    const pos = getMousePos(e);
    lastX = pos.x;
    lastY = pos.y;
    // Start new path
    const newPath = {
      tool: currentTool,
      color: currentTool === 'pencil' ? currentColor : 'erase',
      size: currentSize,
      points: [{ x: lastX, y: lastY }]
    };
    paths.push(newPath);
    // Set up drawing style
    ctx.lineCap = 'round';
    ctx.lineJoin = 'round';
    ctx.lineWidth = currentSize;

    if (currentTool === 'pencil') {
      ctx.strokeStyle = currentColor;
      ctx.globalCompositeOperation = 'source-over';
    } else if (currentTool === 'eraser') {
      ctx.globalCompositeOperation = 'destination-out';
    }
    ctx.beginPath();
    ctx.moveTo(lastX, lastY);
  }

  function draw(e) {
    if (!isDrawing || !canDraw) return;
    const pos = getMousePos(e);
    const currentPath = paths[paths.length - 1];
    currentPath.points.push({ x: pos.x, y: pos.y });
    ctx.lineTo(pos.x, pos.y);
    ctx.stroke();
    lastX = pos.x;
    lastY = pos.y;
  }

  function stopDrawing() {
    if (!isDrawing) return;
    isDrawing = false;
    ctx.beginPath();
    if (canDraw) {
      saveToServer();
    }
  }

  // Draw a single path
  function drawPath(pathData) {
    if (!pathData.points || pathData.points.length < 2) return;
    ctx.lineCap = 'round';
    ctx.lineJoin = 'round';
    ctx.lineWidth = pathData.size;

    if (pathData.tool === 'pencil') {
      ctx.strokeStyle = pathData.color;
      ctx.globalCompositeOperation = 'source-over';
    } else if (pathData.tool === 'eraser') {
      ctx.globalCompositeOperation = 'destination-out';
    }

    ctx.beginPath();
    ctx.moveTo(pathData.points[0].x, pathData.points[0].y);
    for (let i = 1; i < pathData.points.length; i++) {
      ctx.lineTo(pathData.points[i].x, pathData.points[i].y);
    }
    ctx.stroke();
  }

  // Save canvas to server as SVG
  function saveToServer() {
    const svgData = canvasToSVG();
    fetch(`/lobbies/${lobbyId}/whiteboards/update_svg`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
      },
      body: JSON.stringify({ svg_data: svgData })
    }).catch(error => {
      console.error('Error saving whiteboard:', error);
    });
  }

  // Convert canvas paths to SVG
  function canvasToSVG() {
    let svgContent = `<svg width="1000" height="500" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1000 500">`;
    paths.forEach(path => {
      if (path.points && path.points.length > 1) {
        let pathString = `M ${path.points[0].x} ${path.points[0].y}`;
        for (let i = 1; i < path.points.length; i++) {
          pathString += ` L ${path.points[i].x} ${path.points[i].y}`;
        }
        if (path.tool === 'pencil') {
          svgContent += `<path d="${pathString}" stroke="${path.color}" stroke-width="${path.size}" fill="none" stroke-linecap="round" stroke-linejoin="round"/>`;
        }
      }
    });
    svgContent += '</svg>';
    return svgContent;
  }

  // Load SVG data from server
  function loadSVGData(svgData) {
    console.log('loadSVGData called with:', svgData);
    ctx.clearRect(0, 0, canvas.width, canvas.height);
    paths = [];

    if (!svgData) {
      console.log('No SVG data provided');
      return;
    }

    const parser = new DOMParser();
    const svgDoc = parser.parseFromString(svgData, 'image/svg+xml');
    const pathElements = svgDoc.querySelectorAll('path');
    console.log('Found', pathElements.length, 'path elements');
    pathElements.forEach(pathEl => {
      const d = pathEl.getAttribute('d');
      const stroke = pathEl.getAttribute('stroke') || '#000000';
      const strokeWidth = parseInt(pathEl.getAttribute('stroke-width')) || 3;
      console.log('Processing path:', d);

      if (d) {
        const points = parseSVGPath(d);
        const pathData = {
          tool: 'pencil',
          color: stroke,
          size: strokeWidth,
          points: points
        };
        paths.push(pathData);
        drawPath(pathData);
      }
    });
    console.log('Loaded', paths.length, 'paths');
  }

  // Parse SVG path data to points
  function parseSVGPath(d) {
    const points = [];
    const commands = d.split(/(?=[ML])/);

    commands.forEach(cmd => {
      if (cmd.startsWith('M') || cmd.startsWith('L')) {
        const coords = cmd.substring(1).trim().split(' ');
        if (coords.length >= 2) {
          points.push({
            x: parseFloat(coords[0]),
            y: parseFloat(coords[1])
          });
        }
      }
    });
    return points;
  }

  // Load existing whiteboard data
  function loadExistingData() {
    console.log('Loading existing whiteboard data for lobby:', lobbyId);
    fetch(`/lobbies/${lobbyId}/whiteboards.json`)
      .then(response => {
        console.log('Response status:', response.status);
        return response.json();
      })
      .then(data => {
        console.log('Received data:', data);
        if (data.svg_data) {
          console.log('SVG data found, length:', data.svg_data.length);
          loadSVGData(data.svg_data);
        } else {
          console.log('No SVG data in response');
        }
      })
      .catch(error => {
        console.error('Error loading whiteboard data:', error);
      });
  }

  // Mouse events
  canvas.addEventListener('mousedown', startDrawing);
  canvas.addEventListener('mousemove', draw);
  canvas.addEventListener('mouseup', stopDrawing);
  canvas.addEventListener('mouseout', stopDrawing);

  // Touch events for mobile support
  canvas.addEventListener('touchstart', (e) => {
    e.preventDefault();
    const touch = e.touches[0];
    const mouseEvent = new MouseEvent('mousedown', {
      clientX: touch.clientX,
      clientY: touch.clientY
    });
    canvas.dispatchEvent(mouseEvent);
  });
  canvas.addEventListener('touchmove', (e) => {
    e.preventDefault();
    const touch = e.touches[0];
    const mouseEvent = new MouseEvent('mousemove', {
      clientX: touch.clientX,
      clientY: touch.clientY
    });
    canvas.dispatchEvent(mouseEvent);
  });
  canvas.addEventListener('touchend', (e) => {
    e.preventDefault();
    const mouseEvent = new MouseEvent('mouseup', {});
    canvas.dispatchEvent(mouseEvent);
  });

  // Initialize canvas size and styling
  function initCanvas() {
    ctx.fillStyle = 'white';
    ctx.fillRect(0, 0, canvas.width, canvas.height);
    canvas.style.cursor = canDraw ? 'crosshair' : 'not-allowed';

    const container = canvas.parentElement;
    const containerWidth = container.clientWidth - 20;
    if (containerWidth < 1000) {
      canvas.style.width = containerWidth + 'px';
      canvas.style.height = (containerWidth * 0.5) + 'px';
    } else {
      canvas.style.width = '1000px';
      canvas.style.height = '500px';
    }
  }

  // Permission check display
  if (!canDraw) {
    const toolbar = document.querySelector('.whiteboard-toolbar');
    const message = document.createElement('div');
    message.style.cssText = 'color: #666; font-style: italic; margin-left: 10px;';
    message.textContent = 'You do not have permission to draw on this whiteboard.';
    toolbar.appendChild(message);
  }

  // Initialize everything
  initCanvas();
  setTimeout(() => {
    loadExistingData();
  }, 500);
  window.addEventListener('resize', initCanvas);
});