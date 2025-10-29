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
