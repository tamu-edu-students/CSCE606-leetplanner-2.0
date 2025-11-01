import { Controller } from "@hotwired/stimulus"
import { subscribeToWhiteboard } from "channels/whiteboard_channel"

// Stimulus controller for hybrid whiteboard functionality
export default class extends Controller {
  static targets = ["canvas", "basicControls", "advancedControls", "display", "color", "brushSize", "status", "enhancedContainer", "cursors"]
  static values = { lobbyId: Number, userId: Number, canDraw: Boolean, svgData: String }

  connect() {
    console.log("[Whiteboard] Stimulus controller connect start")
    try {
      if (!this.element) {
        console.warn('[Whiteboard] No element present during connect')
      }
      // Basic sanity of data attributes
      console.log('[Whiteboard] Data values', {
        lobbyId: this.lobbyIdValue,
        userId: this.userIdValue,
        canDraw: this.canDrawValue,
        svgLength: this.svgDataValue ? this.svgDataValue.length : 0
      })
    } catch (e) {
      console.error('[Whiteboard] Connect pre-init diagnostics failed', e)
    }
    this.initializeWhiteboard()
  }

  async initializeWhiteboard() {
    // Deterministic loader: ensure fabric script present, then init.
    await this.ensureFabricScript()
    const fabric = window.fabric
    if (!fabric || typeof fabric.Canvas !== 'function') {
      console.warn('[Whiteboard] Fabric 5.x Canvas constructor missing; attempting fallback to Fabric 4.6.0')
      await this.loadFabricLegacy()
    }
    const fabFinal = window.fabric
    console.log('[Whiteboard] Fabric diagnostics', {
      present: !!fabFinal,
      keys: fabFinal ? Object.keys(fabFinal).slice(0,20) : [],
      canvasType: fabFinal && fabFinal.Canvas ? typeof fabFinal.Canvas : 'missing'
    })
    if (fabFinal && typeof fabFinal.Canvas === 'function' && this.canDrawValue) {
      console.log("[Whiteboard] Fabric.js ready -> enhanced mode")
      this.setupEnhancedWhiteboard(fabFinal)
    } else if (fabFinal && typeof fabFinal.Canvas === 'function') {
      console.log("[Whiteboard] Fabric.js ready -> view-only mode")
      this.setupViewOnlyMode(fabFinal)
    } else {
      console.warn("[Whiteboard] Fabric.js not available -> basic mode")
      this.setupBasicMode()
    }
  }

  async ensureFabricScript() {
    if (window.fabric) return
    if (document.getElementById('fabric-fallback-script')) {
      // Wait until loaded
      await new Promise(r => {
        const check = () => { if (window.fabric) r(); else setTimeout(check, 50) }
        check()
      })
      return
    }
    await new Promise(resolve => {
      const script = document.createElement('script')
      script.id = 'fabric-fallback-script'
      script.src = 'https://cdn.jsdelivr.net/npm/fabric@5.3.0/dist/fabric.min.js'
      script.async = true
      script.onload = () => resolve()
      script.onerror = () => {
        console.error('[Whiteboard] Failed to load Fabric script')
        resolve()
      }
      document.head.appendChild(script)
    })
    // Poll for Canvas constructor up to 2 seconds
    await new Promise(r => {
      const start = Date.now()
      const check = () => {
        if (window.fabric && typeof window.fabric.Canvas === 'function') { r() }
        else if (Date.now() - start > 2000) { r() }
        else { setTimeout(check, 50) }
      }
      check()
    })
  }

  async loadFabricLegacy() {
    // Load Fabric 4.6.0 if newer version failed
    if (document.getElementById('fabric-legacy-script')) {
      await new Promise(r => { const check=()=>{ if(window.fabric && window.fabric.Canvas) r(); else setTimeout(check,50)}; check() })
      return
    }
    await new Promise(resolve => {
      const script = document.createElement('script')
      script.id = 'fabric-legacy-script'
      script.src = 'https://cdn.jsdelivr.net/npm/fabric@4.6.0/dist/fabric.min.js'
      script.async = true
      script.onload = () => resolve()
      script.onerror = () => { console.error('[Whiteboard] Failed to load Fabric legacy script'); resolve() }
      document.head.appendChild(script)
    })
    // Poll again for legacy version
    await new Promise(r => {
      const start = Date.now()
      const check = () => {
        if (window.fabric && typeof window.fabric.Canvas === 'function') { r() }
        else if (Date.now() - start > 2000) { r() }
        else { setTimeout(check, 50) }
      }
      check()
    })
  }

  setupPlainCanvasFallback() {
    // Basic drawing using native canvas if Fabric still unavailable
    if (this.hasDisplayTarget) this.displayTarget.style.display = 'none'
    if (this.hasEnhancedContainerTarget) this.enhancedContainerTarget.style.display = 'block'
    const canvasEl = this.canvasTarget
    const ctx = canvasEl.getContext('2d')
    canvasEl.width = 800; canvasEl.height = 300
    canvasEl.style.background = '#ffffff'
    // Draw grid
    ctx.strokeStyle = '#e0e0e0'; ctx.lineWidth = 0.5
    for (let y=0; y<=300; y+=20){ ctx.beginPath(); ctx.moveTo(0,y); ctx.lineTo(800,y); ctx.stroke() }
    for (let x=0; x<=800; x+=20){ ctx.beginPath(); ctx.moveTo(x,0); ctx.lineTo(x,300); ctx.stroke() }
    let drawing = false; let last=null
    canvasEl.addEventListener('mousedown', e=>{ drawing=true; last=this._pointer(e) })
    canvasEl.addEventListener('mousemove', e=>{ if(!drawing) return; const p=this._pointer(e); ctx.strokeStyle='#000'; ctx.lineWidth=2; ctx.beginPath(); ctx.moveTo(last.x,last.y); ctx.lineTo(p.x,p.y); ctx.stroke(); last=p })
    window.addEventListener('mouseup', ()=> drawing=false)
    console.warn('[Whiteboard] Using plain canvas fallback (Fabric unavailable)')
  }

  _pointer(e){ const rect=this.canvasTarget.getBoundingClientRect(); return { x: e.clientX-rect.left, y: e.clientY-rect.top } }

  setupEnhancedWhiteboard(fabric) {
    // Hide basic controls, show advanced controls
    if (this.hasBasicControlsTarget) {
      this.basicControlsTarget.style.display = 'none'
    }
    if (this.hasAdvancedControlsTarget) {
      this.advancedControlsTarget.style.display = 'block'
    }
    if (this.hasEnhancedContainerTarget) {
      this.enhancedContainerTarget.style.display = 'block'
    }
    // Hide static display (fallback SVG) when enhanced active
    if (this.hasDisplayTarget) {
      this.displayTarget.style.display = 'none'
    }

    // Initialize Fabric.js canvas
    this.fabricCanvas = new fabric.Canvas(this.canvasTarget, {
      width: 800,
      height: 300,
      backgroundColor: '#ffffff',
      selection: true,
      preserveObjectStacking: true
    })

    // Pan & zoom state
    this.viewportTransform = this.fabricCanvas.viewportTransform
    this.isPanning = false
    this.currentZoom = 1

    // Load existing SVG data if available
    if (this.svgDataValue) {
      this.loadExistingSVG(fabric)
    }

    // Subscribe to live updates (static import ensures asset present)
    this.subscription = subscribeToWhiteboard(this.lobbyIdValue, (payload) => {
      if (payload.svg_data) this.refreshFromRemote(payload.svg_data, fabric)
      if (payload.cursor && this.hasCursorsTarget) this.renderRemoteCursor(payload.cursor)
    })

    // Set up drawing tools
  this.setupDrawingTools(fabric)
    
    // Set up event handlers
    this.setupEventHandlers()

    // Add grid background
    this.addGridBackground(fabric)
    this.setupPanAndZoom()
    this.setupKeyboardShortcuts(fabric)
    this.cursorBroadcastLoop()
  }

  setupViewOnlyMode(fabric) {
    // Show display only, hide all controls
    if (this.hasBasicControlsTarget) {
      this.basicControlsTarget.style.display = 'none'
    }
    if (this.hasAdvancedControlsTarget) {
      this.advancedControlsTarget.style.display = 'none'
    }

    // Initialize read-only canvas
    this.fabricCanvas = new fabric.Canvas(this.canvasTarget, {
      width: 800,
      height: 300,
      backgroundColor: '#ffffff',
      selection: false,
      interactive: false
    })

    // Load existing SVG data
    if (this.svgDataValue) {
      this.loadExistingSVG(fabric)
    }

    // Add grid background
    this.addGridBackground(fabric)
  }

  setupBasicMode() {
    // Keep basic controls visible, hide advanced controls
    if (this.hasAdvancedControlsTarget) {
      this.advancedControlsTarget.style.display = 'none'
    }
    if (this.hasBasicControlsTarget) {
      this.basicControlsTarget.style.display = 'block'
    }
    
    console.log("Using server-side whiteboard controls")
    // Minimal tools placeholder so click handlers don't explode if user clicks early
    this.tools = this.tools || { select: () => {}, pen: () => {}, text: () => {}, rectangle: () => {}, circle: () => {}, sticky: () => {}, pan: () => {} }
  }

  loadExistingSVG(fabric) {
    try {
      fabric.loadSVGFromString(this.svgDataValue, (objects, options) => {
        const obj = fabric.util.groupSVGElements(objects, options)
        this.fabricCanvas.add(obj)
        this.fabricCanvas.renderAll()
      })
    } catch (error) {
      console.log("Could not load existing SVG:", error)
    }
  }

  addGridBackground(fabric) {
    const gridSize = 20
    const canvasWidth = 800
    const canvasHeight = 300

    // Create grid pattern
    const gridLines = []
    
    // Vertical lines
    for (let i = 0; i <= canvasWidth; i += gridSize) {
      const line = new fabric.Line([i, 0, i, canvasHeight], {
        stroke: '#e0e0e0',
        strokeWidth: 0.5,
        selectable: false,
        evented: false
      })
      gridLines.push(line)
    }

    // Horizontal lines
    for (let i = 0; i <= canvasHeight; i += gridSize) {
      const line = new fabric.Line([0, i, canvasWidth, i], {
        stroke: '#e0e0e0',
        strokeWidth: 0.5,
        selectable: false,
        evented: false
      })
      gridLines.push(line)
    }

    // Add grid to canvas
    gridLines.forEach(line => {
      this.fabricCanvas.add(line)
      this.fabricCanvas.sendToBack(line)
    })
  }

  setupDrawingTools(fabric) {
    this.currentTool = 'select'
    this.isDrawing = false

    // Tool state
    this.tools = {
      select: () => this.setSelectMode(),
      pen: () => this.setPenMode(fabric),
      text: () => this.setTextMode(fabric),
      rectangle: () => this.setRectangleMode(fabric),
      circle: () => this.setCircleMode(fabric),
      sticky: () => this.setStickyMode(fabric),
      pan: () => this.setPanMode()
    }
  }

  setupEventHandlers() {
    // Save changes to server
    this.fabricCanvas.on('path:created', () => this.saveToServer())
    this.fabricCanvas.on('object:added', () => this.saveToServer())
    this.fabricCanvas.on('object:modified', () => this.saveToServer())
    this.fabricCanvas.on('object:removed', () => this.saveToServer())

    // Click to add text/shapes
    this.fabricCanvas.on('mouse:down', (options) => {
      if (this.currentTool !== 'select' && this.currentTool !== 'pen') {
        this.handleCanvasClick(options)
      }
    })
  }

  handleCanvasClick(options) {
    const pointer = this.fabricCanvas.getPointer(options.e)
    
    switch (this.currentTool) {
      case 'text':
        this.addTextAtPosition(pointer.x, pointer.y)
        break
      case 'rectangle':
        this.addRectangleAtPosition(pointer.x, pointer.y)
        break
      case 'circle':
        this.addCircleAtPosition(pointer.x, pointer.y)
        break
      case 'sticky':
        this.addStickyAtPosition(pointer.x, pointer.y)
        break
    }
  }

  // Tool methods
  setSelectMode() {
    this.currentTool = 'select'
    this.fabricCanvas.isDrawingMode = false
    this.updateToolButtons('select')
  }

  setPenMode(fabric) {
    this.currentTool = 'pen'
    this.fabricCanvas.isDrawingMode = true
    this.fabricCanvas.freeDrawingBrush = new fabric.PencilBrush(this.fabricCanvas)
    this.fabricCanvas.freeDrawingBrush.width = this.hasBrushSizeTarget ? parseInt(this.brushSizeTarget.value, 10) : 3
    this.fabricCanvas.freeDrawingBrush.color = this.hasColorTarget ? this.colorTarget.value : '#000000'
    this.updateToolButtons('pen')
  }

  setTextMode(fabric) {
    this.currentTool = 'text'
    this.fabricCanvas.isDrawingMode = false
    this.updateToolButtons('text')
  }

  setRectangleMode(fabric) {
    this.currentTool = 'rectangle'
    this.fabricCanvas.isDrawingMode = false
    this.updateToolButtons('rectangle')
  }

  setCircleMode(fabric) {
    this.currentTool = 'circle'
    this.fabricCanvas.isDrawingMode = false
    this.updateToolButtons('circle')
  }

  setStickyMode(fabric) {
    this.currentTool = 'sticky'
    this.fabricCanvas.isDrawingMode = false
    this.updateToolButtons('sticky')
  }

  setPanMode() {
    this.currentTool = 'pan'
    this.fabricCanvas.isDrawingMode = false
    this.updateToolButtons('pan')
  }

  // Add elements methods
  addTextAtPosition(x, y) {
    const text = new fabric.IText('Double click to edit', {
      left: x,
      top: y,
      fontFamily: 'Arial',
      fontSize: 16,
      fill: '#000000'
    })
    this.fabricCanvas.add(text)
    this.fabricCanvas.setActiveObject(text)
    this.saveToServer()
  }

  addRectangleAtPosition(x, y) {
    const rect = new fabric.Rect({
      left: x,
      top: y,
      width: 100,
      height: 60,
      fill: 'transparent',
      stroke: '#000000',
      strokeWidth: 2
    })
    this.fabricCanvas.add(rect)
    this.saveToServer()
  }

  addCircleAtPosition(x, y) {
    const circle = new fabric.Circle({
      left: x,
      top: y,
      radius: 30,
      fill: 'transparent',
      stroke: '#000000',
      strokeWidth: 2
    })
    this.fabricCanvas.add(circle)
    this.saveToServer()
  }

  addStickyAtPosition(x, y) {
    const group = new fabric.Group([], { left: x, top: y })
    const rect = new fabric.Rect({ width: 160, height: 120, fill: '#fff9c4', stroke: '#f0d24c', strokeWidth: 2, rx: 6, ry: 6 })
    const text = new fabric.IText('Sticky note', { left: 10, top: 10, fontFamily: 'Arial', fontSize: 18, fill: '#333', width: 140 })
    group.addWithUpdate(rect)
    group.addWithUpdate(text)
    this.fabricCanvas.add(group)
    this.fabricCanvas.setActiveObject(group)
    this.saveToServer()
  }

  updateToolButtons(activeTool) {
    // Update button states
    this.element.querySelectorAll('.tool-btn').forEach(btn => {
      btn.classList.remove('active')
    })
    
    const activeBtn = this.element.querySelector(`[data-tool="${activeTool}"]`)
    if (activeBtn) {
      activeBtn.classList.add('active')
    }
  }

  // Server communication
  async saveToServer() {
    if (!this.fabricCanvas) return
    // Throttle saves (500ms window)
    const now = Date.now()
    if (this._lastSave && now - this._lastSave < 500) return
    this._lastSave = now

    try {
      const svgData = this.fabricCanvas.toSVG()
      const response = await fetch(`/lobbies/${this.lobbyIdValue}/whiteboards/update_svg`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
        },
        body: JSON.stringify({ svg_data: svgData })
      })
      if (!response.ok) throw new Error('Failed to save to server')
      this.reportStatus('Saved')
      // Broadcast via ActionCable
      if (this.subscription) {
        this.subscription.send({ lobby_id: this.lobbyIdValue, svg_data: svgData })
      }
    } catch (error) {
      console.error('Error saving to server:', error)
      this.reportStatus('Save failed')
    }
  }

  refreshFromRemote(svg, fabric) {
    if (!this.fabricCanvas) return
    try {
      // Instead of clearing entire canvas (which can delete local in-progress objects),
      // we diff by replacing a single grouped SVG layer tagged 'remote-svg'.
      const existing = this.fabricCanvas.getObjects().find(o => o.remoteSVG)
      fabric.loadSVGFromString(svg, (objects, options) => {
        const group = fabric.util.groupSVGElements(objects, options)
        group.remoteSVG = true
        if (existing) {
          const idx = this.fabricCanvas.getObjects().indexOf(existing)
          this.fabricCanvas.remove(existing)
          this.fabricCanvas.insertAt(group, idx, false)
        } else {
          this.fabricCanvas.add(group)
        }
        this.fabricCanvas.renderAll()
      })
    } catch (e) {
      console.error('Failed to refresh from remote', e)
    }
  }

  reportStatus(message) {
    if (this.hasStatusTarget) {
      this.statusTarget.textContent = message
      setTimeout(() => { if (this.hasStatusTarget) this.statusTarget.textContent = '' }, 2000)
    }
  }

  changeColor(event) {
    if (!this.fabricCanvas) return
    const color = event.target.value
    if (this.fabricCanvas.isDrawingMode) {
      this.fabricCanvas.freeDrawingBrush.color = color
    } else if (this.currentTool === 'pen') {
      this.fabricCanvas.freeDrawingBrush.color = color
    }
  }

  changeBrushSize(event) {
    if (!this.fabricCanvas) return
    const size = parseInt(event.target.value, 10)
    if (this.fabricCanvas.isDrawingMode) {
      this.fabricCanvas.freeDrawingBrush.width = size
    }
  }

  // Action methods for tool buttons
  selectTool(event) {
    event.preventDefault()
    const tool = event.target.dataset.tool
    if (!this.tools) {
      console.warn('[Whiteboard] tools map missing; attempting enhanced initialization with fallback fabric...')
      if (window.fabric && this.canDrawValue) {
        this.setupEnhancedWhiteboard(window.fabric)
      } else if (window.fabric) {
        this.setupViewOnlyMode(window.fabric)
      } else {
        console.warn('[Whiteboard] fabric still unavailable; retaining basic mode')
      }
    }
    if (this.tools && this.tools[tool]) {
      try {
        this.tools[tool]()
      } catch (e) {
        console.error('[Whiteboard] Tool activation failed', tool, e)
      }
    } else {
      console.warn('[Whiteboard] Unknown or uninitialized tool:', tool)
    }
  }

  clearCanvas(event) {
    event.preventDefault()
    if (confirm('Clear the whiteboard? This cannot be undone.')) {
      this.fabricCanvas.clear()
      this.addGridBackground(window.fabric)
      this.pushHistory()
      this.saveToServer()
    }
  }

  // Undo/Redo
  undo() {
    if (!this._history) return
    if (this._historyIndex > 0) {
      this._historyIndex--
      this.loadSVGSnapshot(this._history[this._historyIndex])
    }
  }

  redo() {
    if (!this._history) return
    if (this._historyIndex < this._history.length - 1) {
      this._historyIndex++
      this.loadSVGSnapshot(this._history[this._historyIndex])
    }
  }

  pushHistory() {
    if (!this.fabricCanvas) return
    const svg = this.fabricCanvas.toSVG()
    if (!this._history) {
      this._history = []
      this._historyIndex = -1
    }
    // Truncate forward history if new change after undo
    if (this._historyIndex < this._history.length - 1) {
      this._history = this._history.slice(0, this._historyIndex + 1)
    }
    this._history.push(svg)
    this._historyIndex = this._history.length - 1
  }

  loadSVGSnapshot(svg) {
    if (!this.fabricCanvas) return
    this.fabricCanvas.clear()
    this.addGridBackground(window.fabric)
    window.fabric.loadSVGFromString(svg, (objects, options) => {
      const obj = window.fabric.util.groupSVGElements(objects, options)
      this.fabricCanvas.add(obj)
      this.fabricCanvas.renderAll()
    })
  }

  setupPanAndZoom() {
    this.fabricCanvas.on('mouse:down', (opt) => {
      if (this.currentTool === 'pan') {
        this.isPanning = true
        this.panStart = opt.e
      }
    })
    this.fabricCanvas.on('mouse:move', (opt) => {
      if (this.isPanning && this.currentTool === 'pan') {
        const e = opt.e
        const vpt = this.fabricCanvas.viewportTransform
        vpt[4] += e.movementX
        vpt[5] += e.movementY
        this.fabricCanvas.requestRenderAll()
      }
    })
    this.fabricCanvas.on('mouse:up', () => {
      this.isPanning = false
    })
    this.canvasTarget.addEventListener('wheel', (e) => {
      e.preventDefault()
      const delta = e.deltaY
      let zoom = this.fabricCanvas.getZoom()
      zoom *= 0.999 ** delta
      zoom = Math.max(0.5, Math.min(zoom, 3))
      this.fabricCanvas.zoomToPoint({ x: e.offsetX, y: e.offsetY }, zoom)
      this.currentZoom = zoom
      this.reportStatus(`Zoom: ${(zoom * 100).toFixed(0)}%`)
    })
  }

  zoomIn() { this.adjustZoom(0.1) }
  zoomOut() { this.adjustZoom(-0.1) }
  adjustZoom(delta) {
    let zoom = this.fabricCanvas.getZoom() + delta
    zoom = Math.max(0.5, Math.min(zoom, 3))
    this.fabricCanvas.setZoom(zoom)
    this.currentZoom = zoom
    this.reportStatus(`Zoom: ${(zoom * 100).toFixed(0)}%`)
  }

  setupKeyboardShortcuts(fabric) {
    this.keyHandler = (e) => {
      if (e.ctrlKey && e.key === 'z') { e.preventDefault(); this.undo() }
      if ((e.ctrlKey && e.key === 'y') || (e.ctrlKey && e.shiftKey && e.key === 'Z')) { e.preventDefault(); this.redo() }
      if (e.key === 'v') this.tools.select?.()
      if (e.key === 'p') this.tools.pen?.()
      if (e.key === 'n') this.tools.sticky?.()
      if (e.key === '+') this.zoomIn()
      if (e.key === '-') this.zoomOut()
      if (e.code === 'Space') { this.setPanMode(); this.reportStatus('Pan mode') }
    }
    document.addEventListener('keydown', this.keyHandler)
    document.addEventListener('keyup', (e) => {
      if (e.code === 'Space' && this.currentTool === 'pan') { this.tools.select?.() }
    })
  }

  cursorBroadcastLoop() {
    if (!this.subscription) return
    this.canvasTarget.addEventListener('mousemove', (e) => {
      if (!this.subscription) return
      const rect = this.canvasTarget.getBoundingClientRect()
      const x = e.clientX - rect.left
      const y = e.clientY - rect.top
      // throttle
      const now = Date.now()
      if (this._lastCursor && now - this._lastCursor < 50) return
      this._lastCursor = now
      this.subscription.send({ lobby_id: this.lobbyIdValue, cursor: { user_id: this.userIdValue, x, y } })
    })
  }

  renderRemoteCursor(cursor) {
    if (!this.hasCursorsTarget) return
    const id = `cursor-${cursor.user_id}`
    let el = this.cursorsTarget.querySelector(`#${id}`)
    if (!el) {
      el = document.createElement('div')
      el.id = id
      el.style.position = 'absolute'
      el.style.width = '12px'
      el.style.height = '12px'
      el.style.background = '#ff4081'
      el.style.borderRadius = '50%'
      el.style.transform = 'translate(-50%, -50%)'
      el.style.pointerEvents = 'none'
      el.style.fontSize = '10px'
      el.style.color = '#fff'
      el.style.display = 'flex'
      el.style.alignItems = 'center'
      el.style.justifyContent = 'center'
      el.textContent = '•'
      this.cursorsTarget.appendChild(el)
    }
    el.style.left = cursor.x + 'px'
    el.style.top = cursor.y + 'px'
  }

  // Extend existing event handlers to push history
  setupEventHandlers() {
    this.fabricCanvas.on('path:created', () => { this.pushHistory(); this.saveToServer() })
    this.fabricCanvas.on('object:added', () => { this.pushHistory(); this.saveToServer() })
    this.fabricCanvas.on('object:modified', () => { this.pushHistory(); this.saveToServer() })
    this.fabricCanvas.on('object:removed', () => { this.pushHistory(); this.saveToServer() })

    this.fabricCanvas.on('mouse:down', (options) => {
      if (this.currentTool !== 'select' && this.currentTool !== 'pen' && this.currentTool !== 'pan') {
        this.handleCanvasClick(options)
      }
    })
  }

  disconnect() {
    if (this.fabricCanvas) {
      this.fabricCanvas.dispose()
    }
    if (this.subscription) {
      this.subscription.unsubscribe()
    }
    document.removeEventListener('keydown', this.keyHandler)
  }
}