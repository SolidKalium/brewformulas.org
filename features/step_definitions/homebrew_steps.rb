def check_formula_names
  # Ensure Homebrew::Formula#name never contains double or simple quotes
  Homebrew::Formula.all.map(&:name).each do |name|
    expect(name).to_not match(/[\"|\']/)
  end
end

Given(/^some formulas exist$/) do
  import = Import.create
  Homebrew::Formula.create!(
    filename: 'a2ps',
    name: 'A2ps',
    homepage: 'http://www.gnu.org/software/a2ps/'
  )
  HomebrewFormula.new_formula(
    name: 'A2ps',
    homepage: 'http://www.gnu.org/software/a2ps/'
  )
  Homebrew::Formula.create!(
    filename: 'a52dec',
    name: 'A52dec',
    homepage: 'http://liba52.sourceforge.net/'
  )
  HomebrewFormula.new_formula(
    name: 'A52dec',
    homepage: 'http://liba52.sourceforge.net/'
  )
  @homebrew_formula_count = Homebrew::Formula.count
  import.ended_at = Time.zone.now
  import.success = true
  import.save
end

Given(/^(\d+)(?: new)? formulas exist$/) do |count|
  count = count.to_i
  count.times do
    counter = Homebrew::Formula.count + 1
    Homebrew::Formula.create!(
      filename: "libfake#{counter}",
      name: "LibFake#{counter}",
      homepage: "http://libfake#{counter}.sourceforge.net/",
      touched_on: Time.now
    )
  end
end

Given(/^following Homebrew formula exists:$/) do |formula|
  formula = formula.rows_hash
  formula['filename'] = formula['name'] if formula['filename'].blank?
  Homebrew::Formula.create!(formula)
end

Given(/^the (.*?) formula has the description "(.*?)"$/) do |name, description|
  formula = Homebrew::Formula.find_by(name: name)
  unless formula
    fail "Unable to find a Homebrew::Formula with name \"#{name}\""
  end
  formula.update_attribute(:description, description)
end

Given(/^the (.*?) formula with homepage "(.*?)" exists$/) do |name, homepage|
  Homebrew::Formula.create!(
    filename: name.downcase,
    name: name,
    homepage: homepage
  )
end

Given(/^the automatically extracted description for the (.*?) formula is "(.*?)"$/) do |name, description|
  formula = Homebrew::Formula.find_by(name: name)
  unless formula
    fail "Unable to find a Homebrew::Formula with name \"#{name}\""
  end
  formula.update_attributes(description: description, description_automatic: true)
end

Given(/^the formula (.*?) is a dependency of (.*?)$/) do |dependence_name, dependent_name|
  dependence = Homebrew::Formula.find_by(name: dependence_name)
  unless dependence
    fail "Unable to find a Homebrew::Formula with name \"#{dependence_name}\""
  end
  dependent = Homebrew::Formula.find_by(name: dependent_name)
  unless dependent
    fail "Unable to find a Homebrew::Formula with name \"#{dependent_name}\""
  end
  dependent.dependencies << dependence
end

Given(/^the formula (.*?) is in conflict with (.*?)$/) do |formula_name, conflict_names|
  formula = Homebrew::Formula.find_by(name: formula_name)
  unless formula
    fail "Unable to find a Homebrew::Formula with name \"#{formula_name}\""
  end
  conflict_names = if conflict_names.include?(' and ')
                     conflict_names.split(' and ')
                   else
                     [*conflict_names]
                   end
  conflict_names.each do |conflict_name|
    conflict = Homebrew::Formula.find_by(name: conflict_name)
    unless conflict
      fail "Unable to find a Homebrew::Formula with name \"#{conflict_name}\""
    end
    formula.conflicts << conflict
  end
end

Given(/^the formulas (.*?) are dependencies of (.*?)$/) do |dependence_names, dependent_name|
  dependent = Homebrew::Formula.find_by(name: dependent_name)
  unless dependent
    fail "Unable to find a Homebrew::Formula with name \"#{dependent_name}\""
  end

  dependence_names.split(',').each do |dependence_name|
    dependence_name.strip!
    dependence_name.gsub!(/and /, '')
    dependence = Homebrew::Formula.find_by(name: dependence_name)
    unless dependence
      fail "Unable to find a Homebrew::Formula with name \"#{dependence_name}\""
    end
    dependent.dependencies << dependence
  end
end

Given(/^the formulas (.*?) are dependents of (.*?)$/) do |dependent_names, dependence_name|
  dependence = Homebrew::Formula.find_by(name: dependence_name)
  unless dependence
    fail "Unable to find a Homebrew::Formula with name \"#{dependence_name}\""
  end

  dependent_names.gsub!(/and /, ',')
  dependent_names.split(',').each do |dependent_name|
    dependent_name.strip!

    next if dependent_name.blank?

    dependent = Homebrew::Formula.find_by(name: dependent_name)
    unless dependent
      fail "Unable to find a Homebrew::Formula with name \"#{dependent_name}\""
    end
    dependence.dependents << dependent
  end
end

Given(/^the (.*?) formula has (.*?) as external dependency$/) do |formula_name, dependence_name|
  formula = Homebrew::Formula.find_by(name: formula_name)
  unless formula
    fail "Unable to find a Homebrew::Formula with name \"#{formula_name}\""
  end

  dependence = Homebrew::Formula.find_by(name: dependence_name)
  unless dependence
    dependence = Homebrew::Formula.create!(
      filename: dependence_name.downcase,
      name: dependence_name
    )
  end
  dependence.update_attribute(:external, true)
  formula.dependencies << dependence
end

Given(/^(\d+) formulas have a description$/) do |count|
  count = count.to_i

  expect(Homebrew::Formula.count).to be >= count

  formulae = Homebrew::Formula.order("RANDOM() LIMIT #{count}")
  formulae.each do |formula|
    formula.update_attribute(:description, 'This is a test')
  end
end

When(/^I click the formula "(.*?)"$/) do |formula|
  click_on formula
end

When(/^the background task to fetch formula description runs$/) do
  FormulaDescriptionFetchWorker.new.perform(Homebrew::Formula.last.id)
end

When(/^I request to update the formula description$/) do
  click_on 'clicking this link'
end

Then(/^there should be some formulas in the database$/) do
  expect(Homebrew::Formula.exists?).to be_truthy,
    "Expected to have formula in the database but didn't."
end

Then(/^new formulas should be available in the database$/) do
  expect(Homebrew::Formula.count).to be > 1
  check_formula_names
end

Then(/^some formulas should be linked as dependencies$/) do
  expect(Homebrew::FormulaDependency.count).to_not be_zero
  check_formula_names
end

Then(/^a formula should be flagged as external dependency$/) do
  expect(Homebrew::Formula.externals.count).to_not be_zero
  check_formula_names
end

Then(/^some formulas should be linked as conflicts$/) do
  expect(Homebrew::FormulaConflict.count).to_not be_zero
  check_formula_names
end

Then(/^formulas should not been updated$/) do
  Homebrew::Formula.select(:created_at, :updated_at).all? do |formula|
    expect(formula.created_at.to_i).to eql(formula.updated_at.to_i)
  end
end

Then(/^no new formula should be in the database$/) do
  expect(Homebrew::Formula.count).to eq(@homebrew_formula_count)
end

Then(/^(a|\d+) new formula should be available in the database$/) do |count|
  formula = Homebrew::Formula.select(:created_at, :updated_at).last
  # Comparing date time isn't working
  expect(formula.created_at.to_i).to eq(formula.updated_at.to_i)
  expect(Homebrew::Formula.count).to eq(count == 'a' ? 1 : count.to_i)
  check_formula_names
end

Then(/^the conflicting formula name should be imported correctly$/) do
  expect(Homebrew::Formula.last.name).to eql('Node@0.12')
end

Then(/^a formula should be updated$/) do
  formulas = Homebrew::Formula.select(:created_at, :updated_at)
                              .to_a.find do |formula|
    formula.created_at != formula.updated_at
  end

  expect(formulas)
    .to be_present, 'Expected to have a formula with a different date ' \
                    "of update than creation but didn't"
  check_formula_names
end

Then(/^a formula should be flagged as deleted in the database$/) do
  expect(Homebrew::Formula.where('touched_on < ?', Time.zone.now).count)
    .to eq(1)

  check_formula_names
end

Then(/^the formula (.*?) should have the following description:$/) do |name, description|
  formula = Homebrew::Formula.find_by(name: name)
  unless formula
    fail "Unable to find a Homebrew::Formula with name \"#{name}\""
  end
  formula_description = formula.description || 'No description available'
  expect(formula_description).to eql(description)
end

Then(/^I should see the (.*?) formula description automatically extracted from the homepage$/) do |name|
  formula = Homebrew::Formula.find_by(name: name)
  unless formula
    fail "Unable to find a Homebrew::Formula with name \"#{name}\""
  end

  xpath = "//blockquote/p[normalize-space(.)='#{formula.description}']"
  description_source = "#{name} homepage"
  xpath << "/../footer[contains(., '"
  xpath << 'Extracted automatically from '
  xpath << "')]/cite[@title=\""
  xpath << formula.homepage
  xpath << '" and normalize-space(.)="'
  xpath << description_source
  xpath << '"]'

  visit formula_path(name)
  expect(page).to have_xpath(xpath)
end

Then(/^I should see the following formula details:$/) do |details|
  details.rows_hash.each_pair do |attribute, value|
    xpath = "//dl[@class='dl-horizontal']/"
    xpath << "dt[normalize-space(.)='#{attribute}']/../"
    xpath << "dd[normalize-space(.)='#{value}']"
    expect(page).to have_xpath(xpath)
  end
end

Then(/^I should see the installation instruction "(.*?)"$/) do |instruction|
  expect(page).to have_xpath("//pre[normalize-space(.)='#{instruction}']")
end

Then(/^I not should see the installation instruction$/) do
  expect(page).to_not have_xpath('//pre')
end

Then(/^I should see some formulas$/) do
  count = Homebrew::Formula.externals.count
  expect(page).to_not have_content("#{count}All")
end

Then(
  /^I should( not)? see( \d+)? (news?|inactives?) formulas?$/
) do |negation, formula_count, status|
  formula_count = 0 if formula_count == 'no'

  status << 's' unless status.ends_with?('s')

  if negation
    expect(page).to_not have_css('.formulae-back h2', text: status.capitalize)
  else
    expect(page).to have_css('.formulae-back h2', text: status.capitalize)
    expect(page).to have_css("##{status} .card", count: formula_count)
  end
end

Then(/^I should see one formula$/) do
  expect(page).to have_content('1All')
end

Then(/^I should not see the (.*?) formula$/) do |name|
  expect(page).to_not have_xpath("//h4[@class='list-group-item-heading' and normalize-space(.)='#{name}']")
end

Then(/^I should see no dependencies$/) do
  expect(page).to have_content('This formula has no dependencies.')
end

Then(/^I should see no conflicts$/) do
  expect(page).to_not have_content('This formula is in conflict with')
end

Then(/^I should see (.*?) as(?: a)? dependenc(?:y|ies)$/) do |dependencies|
  all_dependencies = if dependencies.include?(',')
                       dependencies.split(',')
                     else
                       [dependencies]
                     end
  dependency = all_dependencies.detect { |dependency| dependency.include?(' and ') }
  if dependency
    all_dependencies.delete(dependency)
    all_dependencies |= dependency.split(' and ')
  end
  all_dependencies.map!(&:strip)

  # Check h4 title
  expect(page).to have_content("Dependencies #{all_dependencies.size}")

  pluralized = (all_dependencies.size > 1 ? "#{all_dependencies.size} dependencies" : 'dependency')
  expect(page).to have_content("The following #{pluralized} will be installed if you install")

  all_dependencies.each do |dependence_name|
    dependence_name.strip!
    dependence_name.gsub!(/and /, '')
    expect(page).to have_xpath("//span[@id='formula-dependencies']/a[normalize-space(.)='#{dependence_name}']")
  end
end

Then(/^I should see (.*?) as dependents?$/) do |dependent_name|
  expect(page).to have_content("This formula is required by #{dependent_name}.")
end

Then(/^I should see a conflict with (.*?)$/) do |conflicts|
  all_conflicts = if conflicts.include?(',')
                    conflicts.split(',')
                  elsif conflicts.include?(' and ')
                    conflicts.split(' and ')
                  else
                    [conflicts]
                  end

  # Check h4 title
  expect(page).to have_content("Conflicts #{all_conflicts.size}")

  all_conflicts.each do |conflict_name|
    conflict_name.strip!
    conflict_name.gsub!(/and /, '')
    xpath = '//ul[@id="formula_conflicts"]/li'
    xpath << "[normalize-space(.)='#{conflict_name}']"
    expect(page).to have_xpath(xpath)
  end
end

Then(/^the formulas with a description coverage should be (\d+)%$/) do |percentage|
  expect(page).to have_xpath('//div[@id="formulas_coverage"]',
                             text: "#{percentage}%")
end
