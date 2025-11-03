# Pin npm packages by running ./bin/importmap

pin "application", preload: true
pin "@hotwired/turbo-rails", to: "turbo.min.js", preload: true
pin "@hotwired/stimulus", to: "stimulus.min.js", preload: true
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js", preload: true

pin_all_from "app/javascript/controllers", under: "controllers"

# Fabric.js for enhanced whiteboard functionality
pin "fabric", to: "https://cdn.jsdelivr.net/npm/fabric@5.3.0/dist/fabric.min.js"

# Standalone whiteboard as fallback
pin "whiteboard_standalone", to: "whiteboard_standalone.js"
pin "@rails/actioncable", to: "actioncable.esm.js"
pin_all_from "app/javascript/channels", under: "channels"
