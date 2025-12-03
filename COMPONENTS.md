# HTML Component Library

This document describes all reusable HTML components (Rails partials) available in the BTC Play application.

## 📋 Table of Contents

1. [Introduction](#introduction)
2. [Component Helpers](#component-helpers)
3. [Available Components](#available-components)
4. [Component Reference](#component-reference)
5. [Best Practices](#best-practices)
6. [Creating New Components](#creating-new-components)

---

## Introduction

### Why Use Components?

✅ **Benefits:**
- **DRY (Don't Repeat Yourself)** - Write once, use everywhere
- **Consistency** - All buttons, cards, etc. look and behave the same
- **Maintainability** - Update in one place, changes apply everywhere
- **Testability** - Easy to test components in isolation
- **Documentation** - Self-documenting code with clear parameters

### Component Location

All reusable components are located in:
```
app/views/components/
```

### How to Use

```erb
<%= render 'components/component_name', param1: value1, param2: value2 %>
```

### Component Architecture

Components follow Rails best practices:
- **No logic in views** - All logic is in helper methods
- **Helpers in `app/helpers/components_helper.rb`**
- **Views only render HTML** - No calculations or conditionals beyond simple checks

---

## Component Helpers

All component logic is handled by helper methods in `app/helpers/components_helper.rb`. This follows Rails best practices by keeping views clean and logic testable.

### Available Helpers

#### `button_classes(variant:, size:, full:, html_class:)`
Generates CSS classes for button component.

```ruby
button_classes(variant: 'primary', size: 'lg', full: true, html_class: 'custom')
# => "btn btn-primary btn-lg btn-full custom"
```

#### `badge_classes(variant:, html_class:)`
Generates CSS classes for badge component.

```ruby
badge_classes(variant: 'success', html_class: '')
# => "badge badge-success"
```

#### `status_badge_classes(status, html_class:)`
Generates CSS classes for status badge component.

```ruby
status_badge_classes('confirmed', html_class: '')
# => "status-badge status-confirmed"
```

#### `form_input_classes(type:, html_class:)`
Generates CSS classes for form inputs based on type.

```ruby
form_input_classes(type: 'email', html_class: '')
# => "form-input"

form_input_classes(type: 'checkbox', html_class: 'custom')
# => "form-checkbox custom"
```

#### `available_credits(wallet)`
Calculates available credits from a wallet object.

```ruby
available_credits(wallet)
# => 150 (total_credits - locked_credits)
```

#### `has_locked_credits?(wallet)`
Checks if wallet has any locked credits.

```ruby
has_locked_credits?(wallet)
# => true/false
```

#### `price_per_credit(package)`
Calculates price per credit for a package.

```ruby
price_per_credit(package)
# => 0.49 (price_usd / credits)
```

---

## Available Components

### UI Components
- [Button](#button) - Primary, secondary, ghost, and link buttons
- [Card](#card) - Standard cards with header, body, and footer
- [Badge](#badge) - Status indicators and labels
- [Tag](#tag) - Category and filter tags
- [Alert](#alert) - User notifications and messages
- [Status Badge](#status-badge) - Transaction status indicators

### Form Components
- [Form Field](#form-field) - All form input types with labels and validation

### Layout Components
- [Hero](#hero) - Hero sections with title, subtitle, and CTAs

### App-Specific Components
- [Package Card](#package-card) - Credit package display
- [Wallet Card](#wallet-card) - Credit wallet balance display

---

## Component Reference

### Button

Reusable button component with multiple variants and sizes.

**File:** `app/views/components/_button.html.erb`

#### Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `text` | String | *required* | Button text |
| `url` | String | nil | Link URL (if present, creates link_to instead of button_tag) |
| `variant` | String | 'primary' | Button style: 'primary', 'secondary', 'ghost', 'link' |
| `size` | String | 'base' | Button size: 'sm', 'base', 'lg' |
| `full` | Boolean | false | Full width button |
| `type` | String | 'button' | Button type: 'submit', 'button', 'reset' |
| `method` | Symbol | :get | HTTP method for links: :get, :post, :delete, etc. |
| `data` | Hash | {} | Data attributes |
| `html_class` | String | '' | Additional CSS classes |

#### Examples

```erb
<!-- Primary button -->
<%= render 'components/button', text: 'Buy Now', url: credit_purchases_path %>

<!-- Secondary button -->
<%= render 'components/button',
    text: 'Learn More',
    url: about_path,
    variant: 'secondary' %>

<!-- Submit button (no URL = button_tag) -->
<%= render 'components/button',
    text: 'Submit Form',
    variant: 'primary',
    type: 'submit' %>

<!-- Delete button with confirmation -->
<%= render 'components/button',
    text: 'Delete Account',
    url: user_path(@user),
    method: :delete,
    variant: 'ghost',
    data: { turbo_confirm: 'Are you sure?' } %>

<!-- Large full-width button -->
<%= render 'components/button',
    text: 'Get Started',
    url: new_user_registration_path,
    variant: 'primary',
    size: 'lg',
    full: true %>
```

---

### Card

Flexible card component with optional header and footer.

**File:** `app/views/components/_card.html.erb`

#### Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `title` | String | nil | Card title (creates header automatically) |
| `hoverable` | Boolean | false | Adds hover lift effect |
| `html_class` | String | '' | Additional CSS classes |

#### Examples

```erb
<!-- Simple card with title -->
<%= render 'components/card', title: 'Account Details' do %>
  <p>Your account information here</p>
<% end %>

<!-- Card with hover effect -->
<%= render 'components/card', hoverable: true do %>
  <p>Hover over me!</p>
<% end %>

<!-- Card with custom header, body, and footer -->
<%= render 'components/card' do |card| %>
  <% card.header do %>
    <h3>Custom Header</h3>
    <p>Subtitle text</p>
  <% end %>

  <% card.body do %>
    <p>Main content goes here</p>
  <% end %>

  <% card.footer do %>
    <%= render 'components/button', text: 'Action', variant: 'primary' %>
  <% end %>
<% end %>

<!-- Simple card without title -->
<%= render 'components/card' do %>
  <h4>My Content</h4>
  <p>Some text</p>
<% end %>
```

---

### Badge

Small status indicators and labels.

**File:** `app/views/components/_badge.html.erb`

#### Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `text` | String | *required* | Badge text |
| `variant` | String | 'primary' | Badge style: 'primary', 'success', 'warning', 'error', 'gray' |
| `html_class` | String | '' | Additional CSS classes |

#### Examples

```erb
<!-- Primary badge -->
<%= render 'components/badge', text: 'New', variant: 'primary' %>

<!-- Success badge -->
<%= render 'components/badge', text: 'Active', variant: 'success' %>

<!-- Warning badge -->
<%= render 'components/badge', text: 'Pending', variant: 'warning' %>

<!-- Error badge -->
<%= render 'components/badge', text: 'Failed', variant: 'error' %>

<!-- Gray badge -->
<%= render 'components/badge', text: 'Draft', variant: 'gray' %>
```

---

### Tag

Category and filter tags.

**File:** `app/views/components/_tag.html.erb`

#### Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `text` | String | *required* | Tag text |
| `html_class` | String | '' | Additional CSS classes |

#### Examples

```erb
<%= render 'components/tag', text: 'Bitcoin' %>
<%= render 'components/tag', text: 'Payment' %>
<%= render 'components/tag', text: 'API' %>
```

---

### Alert

User notifications and messages.

**File:** `app/views/components/_alert.html.erb`

#### Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `message` | String | *required* | Alert message |
| `variant` | String | 'info' | Alert style: 'success', 'warning', 'error', 'info' |
| `dismissible` | Boolean | false | Adds close button |
| `html_class` | String | '' | Additional CSS classes |

#### Examples

```erb
<!-- Success alert -->
<%= render 'components/alert',
    message: 'Payment successful!',
    variant: 'success' %>

<!-- Warning alert -->
<%= render 'components/alert',
    message: 'Your session will expire soon.',
    variant: 'warning',
    dismissible: true %>

<!-- Error alert -->
<%= render 'components/alert',
    message: 'Payment failed. Please try again.',
    variant: 'error' %>

<!-- Info alert with block content -->
<%= render 'components/alert', variant: 'info' do %>
  <strong>Tip:</strong> Bitcoin payments may take 10-30 minutes to confirm.
<% end %>
```

---

### Status Badge

Transaction status indicators.

**File:** `app/views/components/_status_badge.html.erb`

#### Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `status` | String | *required* | Transaction status: 'pending', 'paid', 'confirmed', 'expired', 'failed' |
| `html_class` | String | '' | Additional CSS classes |

#### Examples

```erb
<%= render 'components/status_badge', status: 'confirmed' %>
<%= render 'components/status_badge', status: 'pending' %>
<%= render 'components/status_badge', status: 'failed' %>

<!-- In a table -->
<td>
  <%= render 'components/status_badge', status: transaction.status %>
</td>
```

---

### Form Field

Unified form field component for all input types.

**File:** `app/views/components/_form_field.html.erb`

#### Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `form` | FormBuilder | *required* | Rails form builder object |
| `field` | Symbol | *required* | Field name |
| `type` | String | 'text' | Input type: 'text', 'email', 'password', 'textarea', 'select', 'checkbox' |
| `label` | String | humanized field | Label text |
| `placeholder` | String | nil | Placeholder text |
| `helper` | String | nil | Helper text below field |
| `error` | String | nil | Error message |
| `options` | Array | nil | Options for select field |
| `required` | Boolean | false | Required field |
| `html_class` | String | '' | Additional CSS classes for input |

#### Examples

```erb
<%= form_with model: @user do |f| %>
  <!-- Email field -->
  <%= render 'components/form_field',
      form: f,
      field: :email,
      type: 'email',
      placeholder: 'you@example.com',
      required: true %>

  <!-- Password field with helper text -->
  <%= render 'components/form_field',
      form: f,
      field: :password,
      type: 'password',
      helper: 'Must be at least 8 characters' %>

  <!-- Textarea -->
  <%= render 'components/form_field',
      form: f,
      field: :bio,
      type: 'textarea',
      label: 'About You' %>

  <!-- Select dropdown -->
  <%= render 'components/form_field',
      form: f,
      field: :country,
      type: 'select',
      options: ['USA', 'Canada', 'UK'] %>

  <!-- Checkbox -->
  <%= render 'components/form_field',
      form: f,
      field: :terms,
      type: 'checkbox',
      label: 'I agree to the terms and conditions' %>

  <!-- Field with error -->
  <%= render 'components/form_field',
      form: f,
      field: :email,
      type: 'email',
      error: 'Email is already taken' %>

  <%= f.submit 'Save', class: 'btn btn-primary' %>
<% end %>
```

---

### Hero

Hero section with title, subtitle, and CTAs.

**File:** `app/views/components/_hero.html.erb`

#### Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `title` | String | *required* | Hero title |
| `subtitle` | String | nil | Hero subtitle |
| `primary_cta_text` | String | nil | Primary button text |
| `primary_cta_url` | String | nil | Primary button URL |
| `secondary_cta_text` | String | nil | Secondary button text |
| `secondary_cta_url` | String | nil | Secondary button URL |
| `html_class` | String | '' | Additional CSS classes |

#### Examples

```erb
<!-- Hero with title and subtitle only -->
<%= render 'components/hero',
    title: 'Welcome to BTC Play',
    subtitle: 'Buy credits with Bitcoin' %>

<!-- Hero with CTAs -->
<%= render 'components/hero',
    title: 'Start Trading Today',
    subtitle: 'Fast, secure Bitcoin transactions',
    primary_cta_text: 'Get Started',
    primary_cta_url: new_user_registration_path,
    secondary_cta_text: 'Learn More',
    secondary_cta_url: about_path %>

<!-- Hero with custom content -->
<%= render 'components/hero',
    title: 'Our Features' do %>
  <div class="grid grid-3 mt-8">
    <!-- Feature cards here -->
  </div>
<% end %>
```

---

### Package Card

Credit package display card (app-specific).

**File:** `app/views/components/_package_card.html.erb`

#### Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `package` | CreditPackage | *required* | CreditPackage model instance |

#### Examples

```erb
<!-- Single package -->
<%= render 'components/package_card', package: @package %>

<!-- Multiple packages in grid -->
<div class="packages-grid">
  <% @credit_packages.each do |package| %>
    <%= render 'components/package_card', package: package %>
  <% end %>
</div>
```

---

### Wallet Card

Credit wallet balance display (app-specific).

**File:** `app/views/components/_wallet_card.html.erb`

#### Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `wallet` | UserCreditWallet | *required* | UserCreditWallet model instance |

#### Examples

```erb
<!-- Display user's wallet -->
<%= render 'components/wallet_card', wallet: current_user.user_credit_wallet %>

<!-- With conditional -->
<% if current_user.user_credit_wallet %>
  <%= render 'components/wallet_card', wallet: current_user.user_credit_wallet %>
<% end %>
```

---

## Best Practices

### 1. Always Use Components When Available

❌ **Don't:**
```erb
<button class="btn btn-primary">Click Me</button>
```

✅ **Do:**
```erb
<%= render 'components/button', text: 'Click Me', variant: 'primary' %>
```

### 2. Keep Components Focused

Each component should do one thing well. Don't create "super components" that try to do everything.

### 3. Use Semantic Parameters

Parameter names should clearly describe what they do:
- ✅ `variant: 'primary'`
- ❌ `style: 1`

### 4. Provide Defaults

Always provide sensible defaults for optional parameters:
```erb
variant ||= 'primary'
size ||= 'base'
```

### 5. Document Your Components

Every component should have:
- Description of what it does
- List of all parameters
- Examples of usage
- Default values

### 6. Test Components

Test components in isolation to ensure they work correctly with different parameters.

### 7. Use Descriptive Variable Names

```erb
# Good
primary_cta_text ||= nil

# Bad
btn_txt ||= nil
```

---

## Creating New Components

### Step-by-Step Guide

1. **Create the partial file**
   ```bash
   touch app/views/components/_my_component.html.erb
   ```

2. **Add documentation header**
   ```erb
   <%
     # My Component
     #
     # Parameters:
     #   param1: Description (required/optional, default: value)
     #
     # Examples:
     #   <%= render 'components/my_component', param1: value %>
   %>
   ```

3. **Define parameters with defaults**
   ```erb
   <%
     param1 ||= 'default_value'
     param2 ||= nil
     html_class ||= ''
   %>
   ```

4. **Build CSS classes**
   ```erb
   <%
     css_classes = ['base-class']
     css_classes << "modifier-#{param1}" if param1.present?
     css_classes << html_class if html_class.present?
     classes = css_classes.join(' ')
   %>
   ```

5. **Write the HTML**
   ```erb
   <div class="<%= classes %>">
     <%= yield if block_given? %>
   </div>
   ```

6. **Document in this file**
   - Add to [Available Components](#available-components)
   - Add full reference with parameters and examples

### Component Template

```erb
<%
  # Component Name
  #
  # Parameters:
  #   param1: Description (required)
  #   param2: Description (optional, default: 'value')
  #
  # Examples:
  #   <%= render 'components/my_component', param1: 'value' %>

  param1 ||= nil
  param2 ||= 'default'
  html_class ||= ''

  return if param1.nil? # Early return if required param missing

  css_classes = ['my-component']
  css_classes << "my-component-#{param2}"
  css_classes << html_class if html_class.present?

  classes = css_classes.join(' ')
%>

<div class="<%= classes %>">
  <%= param1 %>
  <%= yield if block_given? %>
</div>
```

---

## Component Patterns

### Pattern 1: Simple Component

For simple components without complex logic:

```erb
<%= render 'components/badge', text: 'New', variant: 'primary' %>
```

### Pattern 2: Component with Block

For components that wrap content:

```erb
<%= render 'components/card', title: 'My Card' do %>
  <p>Card content</p>
<% end %>
```

### Pattern 3: Component in Loop

For rendering collections:

```erb
<div class="grid grid-3">
  <% @items.each do |item| %>
    <%= render 'components/item_card', item: item %>
  <% end %>
</div>
```

### Pattern 4: Conditional Component

For conditional rendering:

```erb
<% if user_signed_in? %>
  <%= render 'components/wallet_card', wallet: current_user.user_credit_wallet %>
<% end %>
```

### Pattern 5: Nested Components

Components can render other components:

```erb
<%= render 'components/card', title: 'Actions' do %>
  <%= render 'components/button', text: 'Save', variant: 'primary' %>
  <%= render 'components/button', text: 'Cancel', variant: 'ghost' %>
<% end %>
```

---

## Migration Examples

### Before (Without Components)

```erb
<div class="package-card">
  <div class="package-header">
    <h3><%= package.name %></h3>
    <div class="package-price">
      <%= number_to_currency(package.price_usd) %>
    </div>
    <p class="package-payment-method">Pay with Bitcoin</p>
  </div>
  <div class="package-body">
    <!-- 30 more lines... -->
  </div>
</div>
```

### After (With Components)

```erb
<%= render 'components/package_card', package: package %>
```

**Benefits:**
- 1 line instead of 30+
- Consistent across the app
- Update once, changes everywhere
- Less prone to errors

---

## Troubleshooting

### Component Not Rendering

1. Check file path: `app/views/components/_component_name.html.erb`
2. Check underscore prefix: `_component_name.html.erb`
3. Check render syntax: `render 'components/component_name'` (no underscore)

### Parameters Not Working

1. Check parameter is defined in component: `param ||= default`
2. Check spelling matches exactly
3. Check parameter type (String, Boolean, etc.)

### Styling Not Applied

1. Check CSS class names match design system
2. Verify CSS files are imported in application.css
3. Check for typos in class names

---

## Summary

### Component Inventory

| Component | Purpose | Common Use Cases |
|-----------|---------|------------------|
| Button | Actions & links | Forms, CTAs, navigation |
| Card | Content containers | Lists, dashboards, layouts |
| Badge | Status indicators | States, counts, labels |
| Tag | Categories | Filters, organization |
| Alert | User messages | Notifications, feedback |
| Status Badge | Transaction status | Payment states |
| Form Field | Form inputs | All forms |
| Hero | Page headers | Landing pages, sections |
| Package Card | Credit packages | Pricing pages |
| Wallet Card | Wallet balance | User dashboard |

### Quick Reference

```erb
# Button
<%= render 'components/button', text: 'Click', variant: 'primary' %>

# Card
<%= render 'components/card', title: 'Title' do %>Content<% end %>

# Badge
<%= render 'components/badge', text: 'New', variant: 'success' %>

# Alert
<%= render 'components/alert', message: 'Success!', variant: 'success' %>

# Form Field
<%= render 'components/form_field', form: f, field: :email, type: 'email' %>

# Hero
<%= render 'components/hero', title: 'Welcome', subtitle: 'Subtitle' %>

# Package Card
<%= render 'components/package_card', package: @package %>

# Wallet Card
<%= render 'components/wallet_card', wallet: @wallet %>
```

---

**Last Updated:** December 2024
**Version:** 1.0.0
**Maintainer:** Development Team
