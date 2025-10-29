// Standalone Miro-like whiteboard implementation
// Works independently of Stimulus for maximum reliability

class MiroWhiteboard {
  constructor(containerId, options = {}) {
    this.container = document.getElementById(containerId)
    if (!this.container) {
      console.error('Whiteboard container not found:', containerId)
      return
    }

    this.options = {
      width: 800,
      height: 400,
      lobbyId: null,
      userId: null,
      canDraw: true,
      ...options
    }

    this.canvas = null
    this.ctx = null
    this.currentTool = 'pen'
    this.isDrawing = false
    this.objects = []
    this.history = []
    this.historyIndex = -1
    this.zoom = 1
    this.panX = 0
    this.panY = 0
    this.isPanning = false
    this.lastPanPoint = null
    
    this.colors = {
      pen: '#000000',
      text: '#000000',
      shape: '#000000'
    }
    this.brushSize = 3

    this.init()
  }

  init() {
    this.createUI()
    this.setupCanvas()
    this.setupEventHandlers()
    this.addGrid()
    this.pushHistory()
    console.log('[MiroWhiteboard] Initialized successfully')
  }

  createUI() {
    this.container.innerHTML = `
      <div class="miro-whiteboard">
        <div class="miro-toolbar">
          <div class="tool-group">
            <button class="tool-btn active" data-tool="pen" title="Draw">✏️ Pen</button>
            <button class="tool-btn" data-tool="text" title="Add Text">📝 Text</button>
            <button class="tool-btn" data-tool="rectangle" title="Rectangle">⬜ Rectangle</button>
            <button class="tool-btn" data-tool="circle" title="Circle">⭕ Circle</button>
            <button class="tool-btn" data-tool="sticky" title="Sticky Note">📌 Sticky</button>
            <button class="tool-btn" data-tool="select" title="Select">👆 Select</button>
            <button class="tool-btn" data-tool="pan" title="Pan">🖐️ Pan</button>
          </div>
          <div class="tool-group">
            <button class="action-btn" data-action="undo" title="Undo">↶</button>
            <button class="action-btn" data-action="redo" title="Redo">↷</button>
            <button class="action-btn" data-action="clear" title="Clear">🗑️</button>
          </div>
          <div class="tool-group">
            <button class="action-btn" data-action="zoom-in" title="Zoom In">➕</button>
            <button class="action-btn" data-action="zoom-out" title="Zoom Out">➖</button>
            <button class="action-btn" data-action="reset-view" title="Reset View">🎯</button>
          </div>
          <div class="tool-group">
            <input type="color" class="color-picker" value="#000000" title="Color">
            <input type="range" class="brush-size" min="1" max="20" value="3" title="Brush Size">
            <span class="brush-preview"></span>
          </div>
          <div class="status"></div>
        </div>
        <div class="miro-canvas-container">
          <canvas class="miro-canvas"></canvas>
          <div class="miro-overlay"></div>
        </div>
      </div>
    `

    // Add CSS styles
    const style = document.createElement('style')
    style.textContent = `
      .miro-whiteboard {
        border: 1px solid #ddd;
        border-radius: 8px;
        overflow: hidden;
        background: #f9f9f9;
      }
      .miro-toolbar {
        background: #fff;
        padding: 10px;
        border-bottom: 1px solid #ddd;
        display: flex;
        align-items: center;
        gap: 15px;
        flex-wrap: wrap;
      }
      .tool-group {
        display: flex;
        align-items: center;
        gap: 5px;
      }
      .tool-btn, .action-btn {
        padding: 8px 12px;
        border: 1px solid #ddd;
        background: #fff;
        border-radius: 6px;
        cursor: pointer;
        font-size: 14px;
        transition: all 0.2s;
      }
      .tool-btn:hover, .action-btn:hover {
        background: #f0f0f0;
        border-color: #999;
      }
      .tool-btn.active {
        background: #007bff;
        color: white;
        border-color: #007bff;
      }
      .color-picker {
        width: 40px;
        height: 32px;
        border: 1px solid #ddd;
        border-radius: 4px;
        cursor: pointer;
      }
      .brush-size {
        width: 80px;
      }
      .brush-preview {
        width: 20px;
        height: 20px;
        border-radius: 50%;
        background: #000;
        display: inline-block;
        margin-left: 5px;
      }
      .miro-canvas-container {
        position: relative;
        overflow: hidden;
        background: #fff;
      }
      .miro-canvas {
        display: block;
        cursor: crosshair;
      }
      .miro-overlay {
        position: absolute;
        top: 0;
        left: 0;
        pointer-events: none;
      }
      .status {
        color: #666;
        font-size: 12px;
        margin-left: auto;
      }
    `
    document.head.appendChild(style)
  }

  setupCanvas() {
    this.canvas = this.container.querySelector('.miro-canvas')
    this.ctx = this.canvas.getContext('2d')
    this.overlay = this.container.querySelector('.miro-overlay')
    
    this.canvas.width = this.options.width
    this.canvas.height = this.options.height
    this.canvas.style.width = this.options.width + 'px'
    this.canvas.style.height = this.options.height + 'px'
    
    this.overlay.style.width = this.options.width + 'px'
    this.overlay.style.height = this.options.height + 'px'
  }

  setupEventHandlers() {
    // Tool selection
    this.container.addEventListener('click', (e) => {
      if (e.target.classList.contains('tool-btn')) {
        this.selectTool(e.target.dataset.tool)
      }
      if (e.target.classList.contains('action-btn')) {
        this.executeAction(e.target.dataset.action)
      }
    })

    // Color picker
    const colorPicker = this.container.querySelector('.color-picker')
    colorPicker.addEventListener('change', (e) => {
      this.colors[this.currentTool] = e.target.value
      this.updateBrushPreview()
    })

    // Brush size
    const brushSize = this.container.querySelector('.brush-size')
    brushSize.addEventListener('input', (e) => {
      this.brushSize = parseInt(e.target.value)
      this.updateBrushPreview()
    })

    // Canvas events
    this.canvas.addEventListener('mousedown', (e) => this.onMouseDown(e))
    this.canvas.addEventListener('mousemove', (e) => this.onMouseMove(e))
    this.canvas.addEventListener('mouseup', (e) => this.onMouseUp(e))
    this.canvas.addEventListener('wheel', (e) => this.onWheel(e))
    this.canvas.addEventListener('dblclick', (e) => this.onDoubleClick(e))

    // Keyboard shortcuts
    document.addEventListener('keydown', (e) => {
      if (e.target.tagName === 'INPUT' || e.target.tagName === 'TEXTAREA') return
      
      if (e.ctrlKey && e.key === 'z') { e.preventDefault(); this.undo() }
      if (e.ctrlKey && e.key === 'y') { e.preventDefault(); this.redo() }
      if (e.key === 'p') this.selectTool('pen')
      if (e.key === 't') this.selectTool('text')
      if (e.key === 'r') this.selectTool('rectangle')
      if (e.key === 'c') this.selectTool('circle')
      if (e.key === 's') this.selectTool('sticky')
      if (e.key === 'v') this.selectTool('select')
      if (e.key === ' ') { e.preventDefault(); this.selectTool('pan') }
    })

    document.addEventListener('keyup', (e) => {
      if (e.key === ' ' && this.currentTool === 'pan') {
        this.selectTool('pen')
      }
    })

    this.updateBrushPreview()
  }

  selectTool(tool) {
    this.currentTool = tool
    
    // Update button states
    this.container.querySelectorAll('.tool-btn').forEach(btn => {
      btn.classList.remove('active')
    })
    this.container.querySelector(`[data-tool="${tool}"]`).classList.add('active')
    
    // Update cursor
    this.canvas.style.cursor = tool === 'pan' ? 'grab' : 'crosshair'
    
    this.setStatus(`Selected: ${tool}`)
  }

  executeAction(action) {
    switch (action) {
      case 'undo': this.undo(); break
      case 'redo': this.redo(); break
      case 'clear': this.clear(); break
      case 'zoom-in': this.zoom *= 1.2; this.redraw(); break
      case 'zoom-out': this.zoom /= 1.2; this.redraw(); break
      case 'reset-view': this.zoom = 1; this.panX = 0; this.panY = 0; this.redraw(); break
    }
  }

  getMousePos(e) {
    const rect = this.canvas.getBoundingClientRect()
    return {
      x: (e.clientX - rect.left - this.panX) / this.zoom,
      y: (e.clientY - rect.top - this.panY) / this.zoom
    }
  }

  onMouseDown(e) {
    if (!this.options.canDraw && this.currentTool !== 'pan' && this.currentTool !== 'select') return
    
    const pos = this.getMousePos(e)
    
    switch (this.currentTool) {
      case 'pen':
        this.isDrawing = true
        this.currentPath = [pos]
        break
      case 'pan':
        this.isPanning = true
        this.lastPanPoint = { x: e.clientX, y: e.clientY }
        this.canvas.style.cursor = 'grabbing'
        break
      case 'text':
        this.addText(pos)
        break
      case 'rectangle':
        this.addRectangle(pos)
        break
      case 'circle':
        this.addCircle(pos)
        break
      case 'sticky':
        this.addSticky(pos)
        break
    }
  }

  onMouseMove(e) {
    const pos = this.getMousePos(e)
    
    if (this.isPanning && this.currentTool === 'pan') {
      this.panX += e.clientX - this.lastPanPoint.x
      this.panY += e.clientY - this.lastPanPoint.y
      this.lastPanPoint = { x: e.clientX, y: e.clientY }
      this.redraw()
    } else if (this.isDrawing && this.currentTool === 'pen') {
      this.currentPath.push(pos)
      this.redraw()
      this.drawCurrentPath()
    }
  }

  onMouseUp(e) {
    if (this.isDrawing && this.currentTool === 'pen') {
      this.objects.push({
        type: 'path',
        points: this.currentPath,
        color: this.colors.pen,
        width: this.brushSize
      })
      this.pushHistory()
      this.isDrawing = false
      this.currentPath = null
    }
    
    if (this.isPanning) {
      this.isPanning = false
      this.canvas.style.cursor = 'grab'
    }
  }

  onWheel(e) {
    e.preventDefault()
    const delta = e.deltaY > 0 ? 0.9 : 1.1
    this.zoom *= delta
    this.zoom = Math.max(0.1, Math.min(this.zoom, 5))
    this.redraw()
  }

  onDoubleClick(e) {
    if (this.currentTool === 'text') {
      const pos = this.getMousePos(e)
      this.editText(pos)
    }
  }

  addText(pos) {
    const text = prompt('Enter text:')
    if (text) {
      this.objects.push({
        type: 'text',
        x: pos.x,
        y: pos.y,
        text: text,
        color: this.colors.text,
        size: this.brushSize * 4
      })
      this.pushHistory()
      this.redraw()
    }
  }

  addRectangle(pos) {
    this.objects.push({
      type: 'rectangle',
      x: pos.x,
      y: pos.y,
      width: 100,
      height: 60,
      color: this.colors.shape,
      filled: false
    })
    this.pushHistory()
    this.redraw()
  }

  addCircle(pos) {
    this.objects.push({
      type: 'circle',
      x: pos.x,
      y: pos.y,
      radius: 30,
      color: this.colors.shape,
      filled: false
    })
    this.pushHistory()
    this.redraw()
  }

  addSticky(pos) {
    const text = prompt('Sticky note text:') || 'Sticky note'
    this.objects.push({
      type: 'sticky',
      x: pos.x,
      y: pos.y,
      width: 120,
      height: 80,
      text: text,
      color: '#fff9c4'
    })
    this.pushHistory()
    this.redraw()
  }

  addGrid() {
    const gridSize = 20
    this.ctx.strokeStyle = '#f0f0f0'
    this.ctx.lineWidth = 0.5
    
    for (let x = 0; x <= this.options.width; x += gridSize) {
      this.ctx.beginPath()
      this.ctx.moveTo(x, 0)
      this.ctx.lineTo(x, this.options.height)
      this.ctx.stroke()
    }
    
    for (let y = 0; y <= this.options.height; y += gridSize) {
      this.ctx.beginPath()
      this.ctx.moveTo(0, y)
      this.ctx.lineTo(this.options.width, y)
      this.ctx.stroke()
    }
  }

  drawCurrentPath() {
    if (!this.currentPath || this.currentPath.length < 2) return
    
    this.ctx.strokeStyle = this.colors.pen
    this.ctx.lineWidth = this.brushSize
    this.ctx.lineCap = 'round'
    this.ctx.lineJoin = 'round'
    
    this.ctx.beginPath()
    this.ctx.moveTo(this.currentPath[0].x, this.currentPath[0].y)
    
    for (let i = 1; i < this.currentPath.length; i++) {
      this.ctx.lineTo(this.currentPath[i].x, this.currentPath[i].y)
    }
    this.ctx.stroke()
  }

  redraw() {
    this.ctx.save()
    this.ctx.clearRect(0, 0, this.canvas.width, this.canvas.height)
    this.ctx.scale(this.zoom, this.zoom)
    this.ctx.translate(this.panX / this.zoom, this.panY / this.zoom)
    
    this.addGrid()
    
    this.objects.forEach(obj => {
      switch (obj.type) {
        case 'path':
          this.drawPath(obj)
          break
        case 'text':
          this.drawText(obj)
          break
        case 'rectangle':
          this.drawRectangle(obj)
          break
        case 'circle':
          this.drawCircle(obj)
          break
        case 'sticky':
          this.drawSticky(obj)
          break
      }
    })
    
    this.ctx.restore()
  }

  drawPath(obj) {
    if (!obj.points || obj.points.length < 2) return
    
    this.ctx.strokeStyle = obj.color
    this.ctx.lineWidth = obj.width
    this.ctx.lineCap = 'round'
    this.ctx.lineJoin = 'round'
    
    this.ctx.beginPath()
    this.ctx.moveTo(obj.points[0].x, obj.points[0].y)
    
    for (let i = 1; i < obj.points.length; i++) {
      this.ctx.lineTo(obj.points[i].x, obj.points[i].y)
    }
    this.ctx.stroke()
  }

  drawText(obj) {
    this.ctx.fillStyle = obj.color
    this.ctx.font = `${obj.size}px Arial`
    this.ctx.fillText(obj.text, obj.x, obj.y)
  }

  drawRectangle(obj) {
    this.ctx.strokeStyle = obj.color
    this.ctx.lineWidth = 2
    
    if (obj.filled) {
      this.ctx.fillStyle = obj.color
      this.ctx.fillRect(obj.x, obj.y, obj.width, obj.height)
    } else {
      this.ctx.strokeRect(obj.x, obj.y, obj.width, obj.height)
    }
  }

  drawCircle(obj) {
    this.ctx.strokeStyle = obj.color
    this.ctx.lineWidth = 2
    
    this.ctx.beginPath()
    this.ctx.arc(obj.x, obj.y, obj.radius, 0, 2 * Math.PI)
    
    if (obj.filled) {
      this.ctx.fillStyle = obj.color
      this.ctx.fill()
    } else {
      this.ctx.stroke()
    }
  }

  drawSticky(obj) {
    // Sticky note background
    this.ctx.fillStyle = obj.color
    this.ctx.fillRect(obj.x, obj.y, obj.width, obj.height)
    
    // Border
    this.ctx.strokeStyle = '#f0d24c'
    this.ctx.lineWidth = 2
    this.ctx.strokeRect(obj.x, obj.y, obj.width, obj.height)
    
    // Text
    this.ctx.fillStyle = '#333'
    this.ctx.font = '14px Arial'
    const lines = obj.text.split('\n')
    lines.forEach((line, i) => {
      this.ctx.fillText(line, obj.x + 8, obj.y + 20 + i * 16)
    })
  }

  undo() {
    if (this.historyIndex > 0) {
      this.historyIndex--
      this.loadHistory()
    }
  }

  redo() {
    if (this.historyIndex < this.history.length - 1) {
      this.historyIndex++
      this.loadHistory()
    }
  }

  clear() {
    if (confirm('Clear the whiteboard?')) {
      this.objects = []
      this.pushHistory()
      this.redraw()
    }
  }

  pushHistory() {
    // Remove future history if we're not at the end
    if (this.historyIndex < this.history.length - 1) {
      this.history = this.history.slice(0, this.historyIndex + 1)
    }
    
    this.history.push(JSON.parse(JSON.stringify(this.objects)))
    this.historyIndex = this.history.length - 1
    
    // Limit history size
    if (this.history.length > 50) {
      this.history.shift()
      this.historyIndex--
    }
  }

  loadHistory() {
    this.objects = JSON.parse(JSON.stringify(this.history[this.historyIndex]))
    this.redraw()
  }

  updateBrushPreview() {
    const preview = this.container.querySelector('.brush-preview')
    preview.style.width = Math.max(8, this.brushSize * 2) + 'px'
    preview.style.height = Math.max(8, this.brushSize * 2) + 'px'
    preview.style.background = this.colors[this.currentTool] || '#000'
  }

  setStatus(message) {
    const status = this.container.querySelector('.status')
    status.textContent = message
    setTimeout(() => status.textContent = '', 2000)
  }

  // Export/Import functionality
  export() {
    return {
      objects: this.objects,
      zoom: this.zoom,
      panX: this.panX,
      panY: this.panY
    }
  }

  import(data) {
    this.objects = data.objects || []
    this.zoom = data.zoom || 1
    this.panX = data.panX || 0
    this.panY = data.panY || 0
    this.redraw()
    this.pushHistory()
  }
}

// Auto-initialize if whiteboard elements are found
document.addEventListener('DOMContentLoaded', () => {
  const whiteboardContainers = document.querySelectorAll('[data-miro-whiteboard]')
  whiteboardContainers.forEach(container => {
    const options = {
      lobbyId: container.dataset.lobbyId,
      userId: container.dataset.userId,
      canDraw: container.dataset.canDraw === 'true'
    }
    new MiroWhiteboard(container.id, options)
  })
})

// Export for manual initialization
window.MiroWhiteboard = MiroWhiteboard