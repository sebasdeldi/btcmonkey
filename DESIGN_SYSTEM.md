# BTC Play Design System

> **Inspired by Bannerbear's clean, conversion-focused design philosophy**

This design system provides a comprehensive, maintainable, and scalable foundation for the BTC Play application. It follows industry best practices using CSS custom properties (design tokens) for consistency across the entire application.

---

## 📚 Documentation

- **[DESIGN_SYSTEM.md](DESIGN_SYSTEM.md)** (this file) - CSS design tokens, styles, and guidelines
- **[COMPONENTS.md](COMPONENTS.md)** - Reusable HTML components (Rails partials)
- **[DESIGN_SYSTEM_QUICK_START.md](DESIGN_SYSTEM_QUICK_START.md)** - Quick reference cheat sheet

---

## 📋 Table of Contents

1. [Architecture](#architecture)
2. [Design Tokens](#design-tokens)
3. [Color System](#color-system)
4. [Typography](#typography)
5. [Spacing](#spacing)
6. [Components](#components)
7. [Layout Patterns](#layout-patterns)
8. [Usage Guidelines](#usage-guidelines)
9. [Examples](#examples)

---

## 🏗️ Architecture

The design system is organized into three main layers:

### File Structure

```
app/
├── assets/stylesheets/
│   ├── design_tokens.css    # CSS custom properties (variables)
│   ├── components.css       # Reusable component styles
│   └── application.css      # Global styles, layout, app-specific styles
│
└── views/components/
    ├── _button.html.erb         # Button component
    ├── _card.html.erb           # Card component
    ├── _badge.html.erb          # Badge component
    ├── _status_badge.html.erb   # Status badge component
    ├── _tag.html.erb            # Tag component
    ├── _alert.html.erb          # Alert component
    ├── _form_field.html.erb     # Form field component
    ├── _hero.html.erb           # Hero section component
    ├── _package_card.html.erb   # Package card component
    └── _wallet_card.html.erb    # Wallet card component
```

### Layer Responsibilities

1. **design_tokens.css** - Single source of truth for all design decisions
   - Colors, typography, spacing, shadows, transitions
   - Never contains actual styles, only variables

2. **components.css** - Reusable UI components
   - Buttons, cards, forms, alerts, badges, navigation
   - Uses design tokens exclusively

3. **application.css** - Application-specific styles
   - Global resets, layout containers, page-specific styles
   - Imports both design_tokens.css and components.css

4. **views/components/** - Reusable HTML components (Rails partials)
   - Pre-built UI components with consistent styling
   - See [COMPONENTS.md](COMPONENTS.md) for full documentation

---

## 🎨 Design Tokens

Design tokens are CSS custom properties that define all design decisions. They provide:

- **Consistency** - Same values used throughout the app
- **Maintainability** - Change once, update everywhere
- **Scalability** - Easy to extend and modify
- **Documentation** - Self-documenting code

### Accessing Design Tokens

Use the `var()` function to access any design token:

```css
.my-component {
  color: var(--color-primary-blue);
  padding: var(--space-4);
  border-radius: var(--radius-md);
  font-size: var(--font-size-base);
}
```

---

## 🎨 Color System

### Primary Colors

Our primary color palette is inspired by Bannerbear's clean, professional aesthetic:

```css
--color-primary-navy: #1a2332;        /* Primary text, headings */
--color-primary-blue: #3b82f6;        /* CTAs, links, brand accent */
--color-primary-blue-dark: #2563eb;   /* Hover states */
--color-primary-blue-darker: #1d4ed8; /* Active states */
--color-primary-white: #ffffff;       /* Backgrounds */
```

**Usage:**
- **Navy** - Headlines, important text, dark backgrounds
- **Blue** - All CTAs, primary actions, links, brand elements
- **White** - Card backgrounds, page backgrounds

### Neutral Grays

A comprehensive gray scale for text, borders, and backgrounds:

```css
--color-gray-50: #f9fafb;   /* Page backgrounds */
--color-gray-100: #f3f4f6;  /* Card backgrounds, subtle fills */
--color-gray-200: #e5e7eb;  /* Borders, dividers */
--color-gray-300: #d1d5db;  /* Input borders */
--color-gray-400: #9ca3af;  /* Placeholder text */
--color-gray-500: #6b7280;  /* Secondary text */
--color-gray-600: #4b5563;  /* Body text */
--color-gray-700: #374151;  /* Emphasized text */
--color-gray-800: #1f2937;  /* Strong emphasis */
--color-gray-900: #111827;  /* Primary text */
```

**Usage Guidelines:**
- Use darker grays (700-900) for text
- Use lighter grays (50-300) for backgrounds and borders
- Mid-range grays (400-600) for secondary text and disabled states

### Semantic Colors

Colors that convey meaning:

```css
/* Success (green) */
--color-success: #10b981;
--color-success-light: #d1fae5;
--color-success-dark: #065f46;

/* Warning (orange) */
--color-warning: #f59e0b;
--color-warning-light: #fef3c7;
--color-warning-dark: #92400e;

/* Error (red) */
--color-error: #ef4444;
--color-error-light: #fee2e2;
--color-error-dark: #991b1b;

/* Info (blue) */
--color-info: #3b82f6;
--color-info-light: #eff6ff;
--color-info-dark: #1e40af;
```

**Usage:**
- **Success** - Confirmed transactions, success messages, checkmarks
- **Warning** - Pending states, caution messages
- **Error** - Failed transactions, error messages, validation errors
- **Info** - Information messages, credit balance display

---

## ✍️ Typography

### Font Families

```css
--font-family-base: -apple-system, BlinkMacSystemFont, 'Segoe UI',
                    'Roboto', 'Helvetica Neue', Arial, sans-serif;
--font-family-mono: 'Monaco', 'Courier New', 'Consolas', monospace;
```

The system uses native font stacks for optimal performance and native look-and-feel across platforms.

### Font Sizes

A harmonious type scale based on a 16px base:

```css
--font-size-xs: 0.75rem;      /* 12px - Tiny labels */
--font-size-sm: 0.875rem;     /* 14px - Small text, captions */
--font-size-base: 1rem;       /* 16px - Body text */
--font-size-lg: 1.125rem;     /* 18px - Large body, intro text */
--font-size-xl: 1.25rem;      /* 20px - H4, small headings */
--font-size-2xl: 1.5rem;      /* 24px - H3 */
--font-size-3xl: 1.875rem;    /* 30px - H2 */
--font-size-4xl: 2.25rem;     /* 36px - H1 */
--font-size-5xl: 3rem;        /* 48px - Display, hero */
--font-size-6xl: 3.75rem;     /* 60px - Large display */
```

### Font Weights

```css
--font-weight-normal: 400;     /* Body text */
--font-weight-medium: 500;     /* Emphasis */
--font-weight-semibold: 600;   /* Buttons, labels */
--font-weight-bold: 700;       /* Headings */
--font-weight-extrabold: 800;  /* Hero text */
```

### Line Heights

```css
--line-height-tight: 1.1;      /* Large headings */
--line-height-snug: 1.2;       /* Small headings */
--line-height-normal: 1.5;     /* UI elements */
--line-height-relaxed: 1.6;    /* Body text */
--line-height-loose: 1.7;      /* Long-form content */
```

### Typography Usage Guide

#### Headings

```html
<h1>Page Title</h1>          <!-- 36px, bold -->
<h2>Section Header</h2>      <!-- 30px, bold -->
<h3>Subsection</h3>          <!-- 24px, semibold -->
<h4>Card Title</h4>          <!-- 20px, semibold -->
```

#### Body Text

```html
<p>Standard paragraph text</p>                    <!-- 16px, normal -->
<p class="text-large">Introductory text</p>       <!-- 18px, normal -->
<small>Small print or captions</small>            <!-- 14px, normal -->
```

---

## 📏 Spacing

### Spacing Scale

Based on a 4px base unit for mathematical consistency:

```css
--space-0: 0;
--space-1: 0.25rem;   /* 4px */
--space-2: 0.5rem;    /* 8px */
--space-3: 0.75rem;   /* 12px */
--space-4: 1rem;      /* 16px */
--space-5: 1.25rem;   /* 20px */
--space-6: 1.5rem;    /* 24px */
--space-8: 2rem;      /* 32px */
--space-10: 2.5rem;   /* 40px */
--space-12: 3rem;     /* 48px */
--space-16: 4rem;     /* 64px */
--space-20: 5rem;     /* 80px */
--space-24: 6rem;     /* 96px */
--space-32: 8rem;     /* 128px */
```

### Spacing Guidelines

**Component Internal Spacing:**
- Small components (buttons, tags): `--space-2` to `--space-4`
- Medium components (cards, forms): `--space-4` to `--space-6`
- Large components (sections): `--space-8` to `--space-12`

**Layout Spacing:**
- Between elements: `--space-4` to `--space-8`
- Between sections: `--space-16` to `--space-20`
- Hero sections: `--space-20` to `--space-32`

### Utility Classes

Quickly apply spacing with utility classes:

```html
<!-- Margin Bottom -->
<div class="mb-2">Small margin bottom</div>    <!-- 8px -->
<div class="mb-4">Medium margin bottom</div>   <!-- 16px -->
<div class="mb-8">Large margin bottom</div>    <!-- 32px -->

<!-- Padding -->
<div class="p-4">Padding all sides</div>       <!-- 16px -->
<div class="py-8">Vertical padding</div>       <!-- 32px top & bottom -->
<div class="px-6">Horizontal padding</div>     <!-- 24px left & right -->
```

---

## 🧩 Components

### Buttons

#### Primary Button

The main call-to-action button:

```html
<button class="btn btn-primary">Get Started</button>
<a href="#" class="btn btn-primary">Buy Credits</a>
```

**When to use:**
- Primary actions (Sign Up, Buy Now, Submit)
- Maximum one per section
- Conversion-focused actions

#### Secondary Button

Alternative actions:

```html
<button class="btn btn-secondary">Learn More</button>
```

**When to use:**
- Secondary actions
- Alternative choices
- Non-critical actions

#### Ghost Button

Subtle, low-emphasis actions:

```html
<button class="btn btn-ghost">Cancel</button>
```

**When to use:**
- Destructive actions (Sign Out, Delete)
- Tertiary actions
- Navigation elements

#### Button Sizes

```html
<button class="btn btn-primary btn-sm">Small</button>
<button class="btn btn-primary">Default</button>
<button class="btn btn-primary btn-lg">Large</button>
<button class="btn btn-primary btn-full">Full Width</button>
```

### Cards

#### Standard Card

```html
<div class="card">
  <div class="card-header">
    <h3>Card Title</h3>
  </div>
  <div class="card-body">
    <p>Card content goes here</p>
  </div>
  <div class="card-footer">
    <button class="btn btn-primary">Action</button>
  </div>
</div>
```

#### Feature Card

For showcasing features with icons:

```html
<div class="feature-card">
  <div class="feature-card-icon">
    <!-- Icon here -->
  </div>
  <h4 class="feature-card-title">Feature Name</h4>
  <p class="feature-card-description">Feature description text</p>
</div>
```

#### Pricing Card

```html
<div class="pricing-card">
  <h3 class="pricing-card-name">Starter</h3>
  <div class="pricing-card-price">$49</div>
  <p class="pricing-card-period">per month</p>
  <ul class="pricing-card-features">
    <li>100 credits</li>
    <li>Bitcoin payments</li>
    <li>Email support</li>
  </ul>
  <button class="btn btn-primary btn-full">Choose Plan</button>
</div>
```

### Forms

#### Form Structure

```html
<form>
  <div class="form-group">
    <label class="form-label" for="email">Email</label>
    <input type="email" id="email" class="form-input" placeholder="you@example.com">
    <p class="form-helper">We'll never share your email</p>
  </div>

  <div class="form-group">
    <label class="form-label" for="password">Password</label>
    <input type="password" id="password" class="form-input">
    <p class="form-error">Password is required</p>
  </div>

  <button type="submit" class="btn btn-primary btn-full">Submit</button>
</form>
```

#### Form Elements

```html
<!-- Text Input -->
<input type="text" class="form-input">

<!-- Select -->
<select class="form-select">
  <option>Choose one</option>
</select>

<!-- Textarea -->
<textarea class="form-textarea" rows="4"></textarea>

<!-- Checkbox -->
<input type="checkbox" class="form-checkbox">
<label>Remember me</label>
```

### Badges & Tags

#### Badges

For status indicators and labels:

```html
<span class="badge badge-primary">New</span>
<span class="badge badge-success">Confirmed</span>
<span class="badge badge-warning">Pending</span>
<span class="badge badge-error">Failed</span>
```

**Common Usage:**
- Transaction statuses
- User roles
- Notification counts

#### Tags

For categories and filters:

```html
<span class="tag">Bitcoin</span>
<span class="tag">Payment</span>
```

### Alerts

For user notifications:

```html
<div class="alert alert-success">
  Payment confirmed! Credits added to your account.
</div>

<div class="alert alert-warning">
  Your transaction is pending confirmation.
</div>

<div class="alert alert-error">
  Payment failed. Please try again.
</div>

<div class="alert alert-info">
  Bitcoin payments may take 10-30 minutes to confirm.
</div>
```

### Navigation

```html
<nav>
  <div class="container">
    <div class="nav-content">
      <div class="nav-left">
        <a href="/" class="nav-brand">BTC Play</a>
        <a href="/credits" class="nav-link">Buy Credits</a>
      </div>

      <div class="nav-links">
        <div class="credit-badge">
          <strong>150</strong>
          <span>credits</span>
        </div>
        <span class="nav-username">username</span>
        <button class="btn btn-ghost">Sign Out</button>
      </div>
    </div>
  </div>
</nav>
```

### Tables

```html
<div class="table-container">
  <table class="table">
    <thead>
      <tr>
        <th>Date</th>
        <th>Package</th>
        <th>Amount</th>
        <th>Status</th>
      </tr>
    </thead>
    <tbody>
      <tr>
        <td>Dec 1, 2024</td>
        <td>Starter Pack</td>
        <td>$49.00</td>
        <td><span class="badge badge-success">Confirmed</span></td>
      </tr>
    </tbody>
  </table>
</div>
```

---

## 📐 Layout Patterns

### Container

Centers content with maximum width:

```html
<div class="container">
  <!-- Content constrained to 1200px max-width -->
</div>
```

**Max widths:**
- Default: `1200px`
- Responsive padding: `48px` desktop, `24px` mobile

### Sections

Vertical spacing for page sections:

```html
<section class="section">        <!-- 80px padding -->
<section class="section-sm">     <!-- 48px padding -->
<section class="section-lg">     <!-- 128px padding -->
```

### Grid Layouts

#### Auto-fill Grid (for packages/pricing)

```html
<div class="grid-auto">
  <div>Item 1</div>
  <div>Item 2</div>
  <div>Item 3</div>
</div>
```

Automatically adjusts columns based on container width (minimum 280px per column).

#### Fixed Column Grids

```html
<div class="grid grid-2">...</div>  <!-- 2 columns -->
<div class="grid grid-3">...</div>  <!-- 3 columns -->
<div class="grid grid-4">...</div>  <!-- 4 columns -->
```

**Responsive behavior:**
- Desktop: Shows specified columns
- Tablet (1024px): 3-4 col grids become 2 col
- Mobile (640px): All grids become 1 column

### Hero Section

```html
<section class="hero">
  <div class="container">
    <h1 class="hero-title">Automate Your Marketing</h1>
    <p class="hero-subtitle">
      Create beautiful images with our API
    </p>
    <div class="hero-cta">
      <a href="#" class="btn btn-primary btn-lg">Get Started Free</a>
      <a href="#" class="btn btn-secondary btn-lg">View Demo</a>
    </div>
  </div>
</section>
```

---

## 📖 Usage Guidelines

### Design Principles (Bannerbear-Inspired)

1. **Whitespace First**
   - Use generous spacing between sections
   - Don't crowd elements
   - Let content breathe

2. **Clear Visual Hierarchy**
   - Use size and weight to establish importance
   - Limit heading levels per page
   - Consistent color usage for meaning

3. **Conversion-Focused**
   - One primary CTA per section
   - Blue for all primary actions
   - Repeat CTAs strategically

4. **Minimal Color Palette**
   - Primarily white backgrounds
   - Navy for text
   - Blue only for CTAs and accents
   - Gray for secondary elements

5. **Consistent Components**
   - Use existing components before creating new ones
   - Follow established patterns
   - Maintain visual consistency

### Accessibility

#### Color Contrast

All color combinations meet WCAG AA standards:
- Navy text on white: ✓ (12.4:1)
- Blue buttons on white: ✓ (4.5:1)
- Gray-600 text on white: ✓ (7.1:1)

#### Focus States

All interactive elements have visible focus states using `--shadow-focus`:

```css
.form-input:focus {
  border-color: var(--color-primary-blue);
  box-shadow: var(--shadow-focus);
}
```

#### Semantic HTML

Use proper HTML elements:
- `<button>` for actions
- `<a>` for navigation
- `<label>` for form labels
- `<nav>`, `<main>`, `<section>` for structure

### Responsive Design

#### Breakpoints

```css
/* Mobile */
@media (max-width: 640px) { }

/* Tablet */
@media (min-width: 641px) and (max-width: 1024px) { }

/* Desktop */
@media (min-width: 1025px) { }
```

#### Mobile-First Approach

Design for mobile first, then enhance for larger screens:

```css
/* Mobile default */
.component {
  padding: var(--space-4);
}

/* Desktop enhancement */
@media (min-width: 1025px) {
  .component {
    padding: var(--space-8);
  }
}
```

### Performance

#### CSS Custom Properties

Design tokens are loaded once and cached by the browser. Changes propagate instantly without recompiling.

#### File Organization

1. `design_tokens.css` - Smallest file, rarely changes
2. `components.css` - Reusable, rarely changes
3. `application.css` - App-specific, may change frequently

This organization maximizes cache efficiency.

---

## 💡 Examples

### Example 1: Credit Package Card

```html
<div class="package-card">
  <div class="package-header">
    <h3>Starter Pack</h3>
    <div class="package-price">$49</div>
    <p class="package-payment-method">Pay with Bitcoin</p>
  </div>

  <div class="package-body">
    <div class="package-credits">
      100
      <span class="package-credits-label">credits</span>
    </div>
    <p class="package-per-credit">$0.49 per credit</p>
    <p class="package-description">
      Perfect for individuals getting started
    </p>
    <button class="btn-buy">Buy Now</button>
  </div>
</div>
```

### Example 2: Transaction Table

```html
<div class="table-container">
  <table class="table">
    <thead>
      <tr>
        <th>Date</th>
        <th>Package</th>
        <th>Status</th>
      </tr>
    </thead>
    <tbody>
      <tr>
        <td>Dec 1, 2024</td>
        <td>Starter Pack</td>
        <td>
          <span class="status-badge status-confirmed">Confirmed</span>
        </td>
      </tr>
    </tbody>
  </table>
</div>
```

### Example 3: Authentication Form

```html
<div class="container py-8">
  <div class="auth-container">
    <div class="auth-card">
      <h2>Log in</h2>

      <form>
        <div class="form-group">
          <label class="form-label" for="email">Email</label>
          <input type="email" id="email" class="form-input" />
        </div>

        <div class="form-group">
          <label class="form-label" for="password">Password</label>
          <input type="password" id="password" class="form-input" />
        </div>

        <div class="form-group">
          <button type="submit" class="btn btn-primary btn-full">
            Log in
          </button>
        </div>
      </form>
    </div>
  </div>
</div>
```

### Example 4: Feature Grid

```html
<div class="container section">
  <h2 class="text-center mb-8">Features</h2>

  <div class="grid grid-3">
    <div class="feature-card">
      <div class="feature-card-icon">⚡</div>
      <h4 class="feature-card-title">Lightning Fast</h4>
      <p class="feature-card-description">
        Process payments in seconds with Bitcoin
      </p>
    </div>

    <div class="feature-card">
      <div class="feature-card-icon">🔒</div>
      <h4 class="feature-card-title">Secure</h4>
      <p class="feature-card-description">
        Bank-level security for all transactions
      </p>
    </div>

    <div class="feature-card">
      <div class="feature-card-icon">💰</div>
      <h4 class="feature-card-title">Low Fees</h4>
      <p class="feature-card-description">
        Save money with cryptocurrency payments
      </p>
    </div>
  </div>
</div>
```

---

## 🚀 Getting Started

### 1. Using Design Tokens in Custom CSS

```css
.my-custom-component {
  /* Colors */
  background-color: var(--color-primary-blue);
  color: var(--color-primary-white);

  /* Spacing */
  padding: var(--space-4) var(--space-6);
  margin-bottom: var(--space-8);

  /* Typography */
  font-size: var(--font-size-lg);
  font-weight: var(--font-weight-semibold);

  /* Effects */
  border-radius: var(--radius-md);
  box-shadow: var(--shadow-md);
  transition: var(--transition-base);
}
```

### 2. Using Components in Rails Views

```erb
<!-- Button -->
<%= link_to "Buy Credits", credit_purchases_path, class: "btn btn-primary" %>

<!-- Card -->
<div class="card">
  <div class="card-body">
    <%= render @item %>
  </div>
</div>

<!-- Form -->
<%= form_with model: @user do |f| %>
  <div class="form-group">
    <%= f.label :email, class: "form-label" %>
    <%= f.email_field :email, class: "form-input" %>
  </div>

  <%= f.submit "Save", class: "btn btn-primary btn-full" %>
<% end %>
```

### 3. Extending the System

To add new design tokens:

1. Add to `design_tokens.css`:
   ```css
   :root {
     --my-new-token: value;
   }
   ```

2. Use in your styles:
   ```css
   .component {
     property: var(--my-new-token);
   }
   ```

---

## 📝 Best Practices

### DO ✅

- Use design tokens for all values
- Follow component patterns
- Maintain consistent spacing
- Use semantic HTML
- Test on mobile devices
- Ensure keyboard navigation works
- Check color contrast

### DON'T ❌

- Use arbitrary pixel values
- Create duplicate components
- Use inline styles (except dynamic values)
- Ignore responsive breakpoints
- Use more than one primary CTA per section
- Mix different spacing scales
- Forget hover/focus states

---

## 🔄 Migration Guide

### Updating Existing Components

If you have existing styles with hardcoded values:

**Before:**
```css
.my-component {
  color: #3b82f6;
  padding: 16px 24px;
  border-radius: 8px;
}
```

**After:**
```css
.my-component {
  color: var(--color-primary-blue);
  padding: var(--space-4) var(--space-6);
  border-radius: var(--radius-md);
}
```

### Converting Inline Styles

**Before:**
```html
<div style="color: #6b7280; font-size: 14px;">Text</div>
```

**After:**
```html
<div class="text-sm" style="color: var(--color-gray-500);">Text</div>
```

Or better yet, use utility classes:
```html
<small>Text</small>
```

---

## 🛠️ Maintenance

### Adding New Components

1. **Check if component exists** - Review components.css first
2. **Use design tokens** - Never hardcode values
3. **Follow naming conventions** - Use BEM or similar methodology
4. **Add documentation** - Update this file with examples
5. **Test responsiveness** - Ensure mobile compatibility

### Updating Design Tokens

Design tokens should rarely change, but when they do:

1. Update value in `design_tokens.css`
2. Changes propagate automatically
3. Test affected pages
4. Document in version control

### Version History

- **v1.0.0** (Dec 2024) - Initial design system implementation
  - Design tokens established
  - Core components created
  - Bannerbear-inspired aesthetic applied

---

## 📚 Additional Resources

### Inspiration

This design system is inspired by:
- [Bannerbear.com](https://www.bannerbear.com) - Clean, conversion-focused design
- Modern SaaS applications - Minimal, professional aesthetics
- Apple Human Interface Guidelines - Clarity and simplicity

### Tools

- **CSS Custom Properties** - [MDN Documentation](https://developer.mozilla.org/en-US/docs/Web/CSS/--*)
- **Color Contrast Checker** - [WebAIM](https://webaim.org/resources/contrastchecker/)
- **Responsive Testing** - Browser DevTools

### Related Reading

- [Design Tokens: What Are They & How Will They Help You?](https://css-tricks.com/what-are-design-tokens/)
- [Building a Design System with CSS Custom Properties](https://www.smashingmagazine.com/2018/05/css-custom-properties-design-systems/)

---

## 💬 Support

For questions about the design system:

1. Review this documentation
2. Check existing components in `components.css`
3. Refer to Bannerbear.com for design inspiration
4. Ask the development team

---

**Last Updated:** December 2024
**Version:** 1.0.0
**Maintainer:** Development Team
