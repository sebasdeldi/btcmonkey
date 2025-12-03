# Design System Overview

Welcome to the BTC Play Design System! This README provides a high-level overview of the design system architecture and how to use it effectively.

## 📚 Documentation Structure

This design system consists of four main documents:

### 1. [DESIGN_SYSTEM.md](DESIGN_SYSTEM.md) - The Complete Guide
**What it covers:**
- CSS design tokens (colors, typography, spacing, etc.)
- Design principles and philosophy
- Layout patterns and grids
- Responsive breakpoints
- Accessibility guidelines
- Best practices

**When to use it:**
- Understanding the color palette
- Learning about spacing and typography scales
- Finding CSS custom properties
- Understanding the design philosophy
- Learning layout patterns

### 2. [COMPONENTS.md](COMPONENTS.md) - HTML Component Library
**What it covers:**
- All reusable HTML components (Rails partials)
- Component parameters and usage
- Code examples for every component
- Best practices for component usage
- How to create new components

**When to use it:**
- Building UI elements (buttons, cards, forms, etc.)
- Looking up component syntax
- Understanding component parameters
- Learning how to create new components

### 3. [STYLESHEET_ARCHITECTURE.md](STYLESHEET_ARCHITECTURE.md) - CSS Organization
**What it covers:**
- Modular CSS file structure
- Component-to-stylesheet mapping
- How to find and update styles
- Adding new components
- Performance benefits

**When to use it:**
- Understanding the CSS file structure
- Finding where styles are defined
- Adding new component styles
- Optimizing performance

### 4. [DESIGN_SYSTEM_QUICK_START.md](DESIGN_SYSTEM_QUICK_START.md) - Cheat Sheet
**What it covers:**
- Quick reference for common patterns
- Copy-paste code snippets
- Most-used design tokens
- Common component examples

**When to use it:**
- Quick lookups while coding
- Common patterns and snippets
- When you need something fast

---

## 🚀 Quick Start

### For Designers

1. **Colors:** See [Color System](DESIGN_SYSTEM.md#color-system)
   - Primary: Navy (#1a2332) and Blue (#3b82f6)
   - Grays: 10 shades from 50 to 900
   - Semantic: Success, Warning, Error, Info

2. **Typography:** See [Typography](DESIGN_SYSTEM.md#typography)
   - System font stack
   - Type scale from 12px to 60px
   - Weights: Normal (400) to Extrabold (800)

3. **Spacing:** See [Spacing](DESIGN_SYSTEM.md#spacing)
   - 4px base unit
   - Scale from 4px to 128px
   - Consistent rhythm

### For Developers

#### Using CSS Classes

```html
<!-- Buttons -->
<button class="btn btn-primary">Primary</button>
<button class="btn btn-secondary">Secondary</button>

<!-- Cards -->
<div class="card">
  <div class="card-body">Content</div>
</div>

<!-- Utilities -->
<div class="mb-4 py-8">Content with spacing</div>
```

#### Using Components

```erb
<!-- Button Component -->
<%= render 'components/button',
    text: 'Buy Now',
    url: credit_purchases_path,
    variant: 'primary' %>

<!-- Card Component -->
<%= render 'components/card', title: 'My Card' do %>
  Card content here
<% end %>

<!-- Form Field Component -->
<%= form_with model: @user do |f| %>
  <%= render 'components/form_field',
      form: f,
      field: :email,
      type: 'email' %>
<% end %>
```

#### Using Design Tokens

```css
.my-custom-component {
  color: var(--color-primary-blue);
  padding: var(--space-4) var(--space-6);
  font-size: var(--font-size-lg);
  border-radius: var(--radius-md);
  box-shadow: var(--shadow-md);
  transition: var(--transition-base);
}
```

---

## 🏗️ Architecture

### Three-Layer System

```
┌─────────────────────────────────────┐
│   HTML Components (Rails Partials)  │ <- Reusable UI components
│   app/views/components/              │
└─────────────────────────────────────┘
                 ↓ uses
┌─────────────────────────────────────┐
│   CSS Components                     │ <- Component styles
│   app/assets/stylesheets/            │
│   components.css                     │
└─────────────────────────────────────┘
                 ↓ uses
┌─────────────────────────────────────┐
│   Design Tokens                      │ <- Design decisions
│   app/assets/stylesheets/            │
│   design_tokens.css                  │
└─────────────────────────────────────┘
```

### How It Works

1. **Design Tokens** define all design decisions (colors, spacing, etc.)
2. **CSS Components** use tokens to style UI elements
3. **HTML Components** use CSS classes to create reusable partials
4. **Your Views** use HTML components to build pages

---

## 📖 Common Tasks

### Task: Create a Button

**Option 1: Use Component (Recommended)**
```erb
<%= render 'components/button',
    text: 'Click Me',
    url: some_path,
    variant: 'primary' %>
```

**Option 2: Use CSS Classes**
```html
<a href="/path" class="btn btn-primary">Click Me</a>
```

---

### Task: Create a Card

**Option 1: Use Component (Recommended)**
```erb
<%= render 'components/card', title: 'Card Title' do %>
  <p>Card content</p>
<% end %>
```

**Option 2: Use CSS Classes**
```html
<div class="card">
  <div class="card-header">Card Title</div>
  <div class="card-body">
    <p>Card content</p>
  </div>
</div>
```

---

### Task: Create a Form

**Using Form Field Components:**
```erb
<%= form_with model: @user do |f| %>
  <%= render 'components/form_field', form: f, field: :email, type: 'email' %>
  <%= render 'components/form_field', form: f, field: :password, type: 'password' %>
  <%= f.submit 'Submit', class: 'btn btn-primary btn-full' %>
<% end %>
```

---

### Task: Display Transaction Status

**Using Status Badge Component:**
```erb
<%= render 'components/status_badge', status: transaction.status %>
```

---

### Task: Style Custom Component

**Using Design Tokens:**
```css
.my-component {
  background: var(--color-primary-white);
  color: var(--color-gray-900);
  padding: var(--space-6);
  border-radius: var(--radius-lg);
  box-shadow: var(--shadow-md);
}

.my-component:hover {
  box-shadow: var(--shadow-lg);
  transform: translateY(-2px);
  transition: var(--transition-base);
}
```

---

## 🎨 Design Principles

### 1. Whitespace First
Use generous spacing. Don't crowd elements.

### 2. Clear Hierarchy
Use size, weight, and color to establish importance.

### 3. Conversion-Focused
Blue for all primary actions. One primary CTA per section.

### 4. Minimal Color
Primarily white backgrounds, navy for text, blue only for CTAs.

### 5. Consistency
Use existing components and patterns before creating new ones.

---

## 📦 Available Components

| Component | Use Case | Documentation |
|-----------|----------|---------------|
| Button | Actions, links, CTAs | [COMPONENTS.md#button](COMPONENTS.md#button) |
| Card | Content containers | [COMPONENTS.md#card](COMPONENTS.md#card) |
| Badge | Status indicators | [COMPONENTS.md#badge](COMPONENTS.md#badge) |
| Status Badge | Transaction status | [COMPONENTS.md#status-badge](COMPONENTS.md#status-badge) |
| Tag | Categories, filters | [COMPONENTS.md#tag](COMPONENTS.md#tag) |
| Alert | Notifications | [COMPONENTS.md#alert](COMPONENTS.md#alert) |
| Form Field | All form inputs | [COMPONENTS.md#form-field](COMPONENTS.md#form-field) |
| Hero | Page headers | [COMPONENTS.md#hero](COMPONENTS.md#hero) |
| Package Card | Credit packages | [COMPONENTS.md#package-card](COMPONENTS.md#package-card) |
| Wallet Card | Credit balance | [COMPONENTS.md#wallet-card](COMPONENTS.md#wallet-card) |

---

## 🎯 Best Practices

### ✅ DO

- Use components whenever possible
- Use design tokens for all CSS values
- Follow established patterns
- Keep components focused and simple
- Test on mobile devices
- Ensure keyboard navigation works
- Check color contrast for accessibility

### ❌ DON'T

- Hardcode pixel values (use tokens)
- Create duplicate components
- Use inline styles (except dynamic values)
- Ignore responsive breakpoints
- Use more than one primary CTA per section
- Mix different spacing scales

---

## 🔄 Workflow

### Adding a New Feature

1. **Check existing components** - Can you use what exists?
2. **Use components** - Build with existing components first
3. **Customize if needed** - Add custom CSS using design tokens
4. **Create new component** - Only if you'll reuse it 3+ times
5. **Document** - Add to COMPONENTS.md if you create something new

### Updating Styles

1. **Find the component** - Check COMPONENTS.md or components.css
2. **Update in one place** - Changes apply everywhere
3. **Use design tokens** - Never hardcode values
4. **Test everywhere** - Check all pages using the component

---

## 📐 Responsive Design

### Breakpoints

- **Mobile:** < 640px
- **Tablet:** 640px - 1024px
- **Desktop:** > 1024px

### Mobile-First

Design for mobile first, then enhance for larger screens:

```css
/* Mobile (default) */
.component {
  padding: var(--space-4);
}

/* Desktop (enhancement) */
@media (min-width: 1025px) {
  .component {
    padding: var(--space-8);
  }
}
```

---

## 🆘 Getting Help

### Finding What You Need

1. **"How do I style X?"** → [DESIGN_SYSTEM.md](DESIGN_SYSTEM.md)
2. **"How do I create a button/card/form?"** → [COMPONENTS.md](COMPONENTS.md)
3. **"Quick snippet for Y?"** → [DESIGN_SYSTEM_QUICK_START.md](DESIGN_SYSTEM_QUICK_START.md)

### Common Questions

**Q: Where are the design tokens defined?**
A: `app/assets/stylesheets/design_tokens.css`

**Q: How do I use a component?**
A: See [COMPONENTS.md](COMPONENTS.md) for all components and examples

**Q: Can I use inline styles?**
A: Avoid them. Use design tokens in your CSS instead.

**Q: How do I add a new color?**
A: Add to `design_tokens.css` as a CSS custom property

**Q: Should I create a new component?**
A: Only if you'll use it 3+ times. Otherwise, use existing components.

---

## 🔍 Examples

### Example 1: Simple Page with Components

```erb
<div class="container py-8">
  <!-- Hero -->
  <%= render 'components/hero',
      title: 'Welcome to BTC Play',
      subtitle: 'Buy credits with Bitcoin',
      primary_cta_text: 'Get Started',
      primary_cta_url: new_user_registration_path %>

  <!-- Feature Grid -->
  <div class="grid grid-3 mt-8">
    <% @features.each do |feature| %>
      <%= render 'components/card', title: feature.name do %>
        <p><%= feature.description %></p>
      <% end %>
    <% end %>
  </div>
</div>
```

### Example 2: Form with Components

```erb
<div class="container py-8">
  <div class="auth-container">
    <div class="auth-card">
      <h2>Sign Up</h2>

      <%= form_with model: @user do |f| %>
        <%= render 'components/form_field', form: f, field: :email, type: 'email' %>
        <%= render 'components/form_field', form: f, field: :password, type: 'password' %>

        <%= render 'components/button',
            text: 'Create Account',
            variant: 'primary',
            full: true,
            type: 'submit' %>
      <% end %>
    </div>
  </div>
</div>
```

### Example 3: Dashboard with Custom Styles

```erb
<div class="container py-8">
  <!-- Wallet -->
  <% if current_user.user_credit_wallet %>
    <%= render 'components/wallet_card', wallet: current_user.user_credit_wallet %>
  <% end %>

  <!-- Packages -->
  <h2 class="mb-4">Available Packages</h2>
  <div class="packages-grid">
    <% @credit_packages.each do |package| %>
      <%= render 'components/package_card', package: package %>
    <% end %>
  </div>

  <!-- Transactions -->
  <% if @transactions.any? %>
    <h2 class="mt-8 mb-4">Recent Transactions</h2>
    <div class="table-container">
      <table class="table">
        <!-- table content -->
      </table>
    </div>
  <% end %>
</div>
```

---

## 📊 File Reference

```
btc-play/
├── app/
│   ├── assets/stylesheets/
│   │   ├── design_tokens.css      # Design tokens
│   │   ├── components.css         # Component styles
│   │   └── application.css        # Global styles
│   │
│   └── views/components/
│       ├── _button.html.erb
│       ├── _card.html.erb
│       ├── _badge.html.erb
│       ├── _status_badge.html.erb
│       ├── _tag.html.erb
│       ├── _alert.html.erb
│       ├── _form_field.html.erb
│       ├── _hero.html.erb
│       ├── _package_card.html.erb
│       └── _wallet_card.html.erb
│
├── DESIGN_SYSTEM.md               # Main documentation
├── COMPONENTS.md                  # Component library
├── DESIGN_SYSTEM_QUICK_START.md   # Cheat sheet
└── DESIGN_SYSTEM_README.md        # This file
```

---

## 🎓 Learning Path

### For New Developers

1. **Start here** → Read this README
2. **Learn the basics** → [DESIGN_SYSTEM_QUICK_START.md](DESIGN_SYSTEM_QUICK_START.md)
3. **Build something** → Use components to build a simple page
4. **Deep dive** → Read [COMPONENTS.md](COMPONENTS.md) for all components
5. **Master it** → Read [DESIGN_SYSTEM.md](DESIGN_SYSTEM.md) for complete understanding

### For Designers

1. **Start here** → Read this README
2. **Colors & Typography** → [DESIGN_SYSTEM.md](DESIGN_SYSTEM.md)
3. **Components** → [COMPONENTS.md](COMPONENTS.md)
4. **Inspiration** → Visit [Bannerbear.com](https://www.bannerbear.com)

---

## 🚀 Next Steps

Now that you understand the design system:

1. **Browse the components** → See [COMPONENTS.md](COMPONENTS.md)
2. **Check the examples** → Look at `app/views/credit_purchases/index.html.erb`
3. **Start building** → Use components in your views
4. **Customize** → Add custom styles using design tokens
5. **Contribute** → Create new components when needed

---

**Version:** 1.0.0
**Last Updated:** December 2024
**Inspired by:** [Bannerbear.com](https://www.bannerbear.com)
