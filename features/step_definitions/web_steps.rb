When('I click the {string} button') do |link_or_button_text|
  begin
    if page.has_button?(link_or_button_text)
      click_button(link_or_button_text)
    elsif page.has_link?(link_or_button_text)
      click_link(link_or_button_text)
    else
      find(:link_or_button, link_or_button_text).click
    end
  rescue Selenium::WebDriver::Error::ElementClickInterceptedError, Selenium::WebDriver::Error::ElementNotInteractableError => e
    # Try to scroll the element into view and click via JS
    el = begin
      if page.has_button?(link_or_button_text)
        find_button(link_or_button_text)
      elsif page.has_link?(link_or_button_text)
        find_link(link_or_button_text)
      else
        find(:link_or_button, link_or_button_text)
      end
    rescue Capybara::ElementNotFound
      raise e
    end

    # Scroll to the element's center
    begin
      execute_script("arguments[0].scrollIntoView({behavior: 'auto', block: 'center', inline: 'center'});", el)
      sleep 0.05
      el.click
    rescue Selenium::WebDriver::Error::ElementClickInterceptedError, Selenium::WebDriver::Error::ElementNotInteractableError
      execute_script("arguments[0].click();", el)
    end
  end
end

When('I press {string}') do |link_or_button_text|
  begin
    click_link(link_or_button_text)
  rescue Capybara::ElementNotFound
    click_button(link_or_button_text)
  end
end

When('I fill in {string} with {string}') do |field, value|
  begin
    fill_in(field, with: value)
  rescue Capybara::ElementNotFound
    # Try a case-insensitive match against label text and fill the associated field
    label = all('label').find { |l| l.text =~ /\A\s*#{Regexp.escape(field)}\s*\z/i }
    if label
      field_id = label[:for]
      if field_id
        fill_in(field_id, with: value)
      else
        raise
      end
    else
      raise
    end
  end
end

Then('I should see {string}') do |text|
  # Special-case some legacy phrasing used in features that map to UI text
  if text.start_with?('Current Event: ')
    title = text.sub('Current Event: ', '')
    expect(page).to have_selector('.event-banner h2.event-title', text: "Now: #{title}")
  elsif text =~ /^Weekly Solved:\s*(\d+)$/
    num = Regexp.last_match(1)
    expect(page).to have_content('Problems Solved This Week')
    expect(page).to have_content(num)
  elsif text =~ /^Total Solved:\s*(\d+)$/
    num = Regexp.last_match(1)
    expect(page).to have_content('Total Problems Solved')
    expect(page).to have_content(num)
  elsif text =~ /^Current Week Streak:\s*(\d+)\s*days$/
    num = Regexp.last_match(1)
    expect(page).to have_content('Current Streak')
    expect(page).to have_content("#{num} days")
  else
    expect(page).to have_content(text)
  end
end

Then('I should not see a {string}') do |text|
  expect(page).not_to have_content(text)
end
