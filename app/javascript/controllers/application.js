// Stimulus application configuration
// Sets up the main Stimulus application instance for managing interactive controllers

import { Application } from "@hotwired/stimulus"

// Start the Stimulus application
const application = Application.start()

// Configure Stimulus development experience
application.debug = false  // Set to true for debugging controller connections and actions
window.Stimulus = application  // Make Stimulus available globally for debugging

// Export the application instance for use by other modules
export { application }

// Manual registration fallback (in case eagerLoadControllersFrom misses or dynamic import 404 occurs)
import WhiteboardController from "./whiteboard_controller"
try {
	if (!application.controllers.find(c => c.identifier === 'whiteboard')) {
		application.register('whiteboard', WhiteboardController)
		console.log('[Stimulus] Whiteboard controller manually registered fallback')
	} else {
		console.log('[Stimulus] Whiteboard controller already registered via eager load')
	}
} catch (e) {
	console.error('[Stimulus] Manual registration failed', e)
}
