Technical Documentation
=======================

This section provides detailed instructions for setting up the development environment, running tests, and deploying the application.

Prerequisites
-------------

Before you begin, ensure you have the following installed on your local machine:

-   Ruby (v3.0.0 or higher)

-   Ruby on Rails (v7.0 or higher)

-   PostgreSQL

-   Bundler

-   Node.js and Yarn

Local Setup Instructions
------------------------

#### 1\. Clone the Repository

Bash

-   git clone https://github.com/tamu-edu-students/CSCE606-group5-project1

-   cd CSCE606-group5-project1

#### 2\. Install Dependencies

Install the required Ruby gems and JavaScript packages.

Bash

-   bundle install

-   yarn install

#### 3\. Set Up Environment Variables

This project uses Google OAuth for authentication, which requires API keys.

1.  Create a file named .env in the root of the project.

2.  Copy the contents below into .env.

3.  Go to the Google Cloud Console to create OAuth 2.0 credentials.

4.  Fill in the GOOGLE_CLIENT_ID and GOOGLE_CLIENT_SECRET in your .env file.

.env

GOOGLE_CLIENT_ID="your_google_client_id_here"\
GOOGLE_CLIENT_SECRET="your_google_client_secret_here"\
GOOGLE_OAUTH_URI=[https://oauth2.googleapis.com/token\
](https://oauth2.googleapis.com/token)ALLOWED_EMAIL_DOMAINS=[tamu.edu\
](http://tamu.edu)PORT=3000

#### 4\. Create, Migrate, and Seed the Database

Bash

-   bin/rails db:create

-   bin/rails db:migrate

-   bin/rails db:seed

-   bin/rails leet_code:seed

#### 5\. Run the Application

This application uses dartsass-rails to compile CSS. The standard way to run the server in development is to use the bin/dev command, which starts both the Rails server and the CSS watcher.

Bash

-   bin/rails dartsass:build

-   bin/dev

You can now access the application at http://localhost:3000.

Running Tests
-------------

This project uses two frameworks for testing: RSpec for unit and controller tests, and Cucumber for acceptance (feature) tests. Before running tests for the first time, prepare your test database:

Bash

-   bin/rails db:test:prepare

#### Running RSpec Tests

To run the entire RSpec test suite:

Bash

bundle exec rspec

To run a single RSpec test file:

Bash

bundle exec rspec spec/controllers/your_controller_spec.rb

#### Running Cucumber Tests

To run the entire Cucumber feature suite:

Bash

bundle exec cucumber

To run a single Cucumber feature file:

Bash

bundle exec cucumber features/your_feature.feature

Deployment
----------

These are high-level instructions for deploying to Heroku:

1.  Create a new Heroku application.

2.  Provision a Heroku Postgres database.

3.  Set the GOOGLE_CLIENT_ID and GOOGLE_CLIENT_SECRET environment variables in the Heroku app settings.

4.  Push your code to Heroku: git push heroku main.

5.  Run database migrations on the Heroku server: heroku run rails db:migrate.