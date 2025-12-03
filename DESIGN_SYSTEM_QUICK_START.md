# Design System Quick Start

A quick reference guide for using the BTC Play Design System.

## 🎨 Common Colors

```css
var(--color-primary-blue)      /* #3b82f6 - Primary CTAs */
var(--color-primary-navy)      /* #1a2332 - Headings */
var(--color-gray-600)          /* #4b5563 - Body text */
var(--color-gray-200)          /* #e5e7eb - Borders */
var(--color-success)           /* #10b981 - Success states */
var(--color-error)             /* #ef4444 - Error states */
```

## 📏 Common Spacing

```css
var(--space-2)    /* 8px */
var(--space-4)    /* 16px */
var(--space-6)    /* 24px */
var(--space-8)    /* 32px */
```

## 🔘 Buttons

```html
<!-- Primary Action -->
<button class="btn btn-primary">Buy Now</button>

<!-- Secondary Action -->
<button class="btn btn-secondary">Learn More</button>

<!-- Subtle Action -->
<button class="btn btn-ghost">Cancel</button>

<!-- Full Width -->
<button class="btn btn-primary btn-full">Submit</button>
```

## 📦 Cards

```html
<!-- Simple Card -->
<div class="card">
  <div class="card-body">
    Content here
  </div>
</div>

<!-- Card with Header -->
<div class="card">
  <div class="card-header">
    <h3>Title</h3>
  </div>
  <div class="card-body">
    Content
  </div>
</div>
```

## 📝 Forms

```html
<div class="form-group">
  <label class="form-label">Email</label>
  <input type="email" class="form-input" placeholder="you@example.com">
  <p class="form-helper">Helper text</p>
</div>
```

## 🏷️ Badges

```html
<span class="badge badge-success">Confirmed</span>
<span class="badge badge-warning">Pending</span>
<span class="badge badge-error">Failed</span>
```

## 🎯 Layout

```html
<!-- Container -->
<div class="container">
  <!-- Max-width 1200px, centered -->
</div>

<!-- Grid -->
<div class="grid grid-3">
  <div>Item 1</div>
  <div>Item 2</div>
  <div>Item 3</div>
</div>

<!-- Auto-fill Grid (for pricing cards) -->
<div class="grid-auto">
  <div>Card 1</div>
  <div>Card 2</div>
</div>
```

## 🎭 Utility Classes

```html
<!-- Spacing -->
<div class="mb-4">Margin bottom 16px</div>
<div class="py-8">Padding top/bottom 32px</div>

<!-- Display -->
<div class="flex items-center gap-4">
  Flexbox with center align and 16px gap
</div>

<!-- Text -->
<div class="text-center">Centered text</div>
```

## 🎨 Using Design Tokens

In your CSS:

```css
.my-component {
  color: var(--color-primary-blue);
  padding: var(--space-4);
  font-size: var(--font-size-lg);
  border-radius: var(--radius-md);
  box-shadow: var(--shadow-md);
}
```

In Rails views:

```erb
<!-- Use component classes -->
<%= link_to "Action", path, class: "btn btn-primary" %>

<!-- Use utility classes -->
<div class="container py-8">
  <h1 class="mb-4">Page Title</h1>
  <p>Content</p>
</div>
```

## 📱 Responsive

All grids automatically adjust:
- Desktop: 3-4 columns
- Tablet: 2 columns
- Mobile: 1 column

## 🎯 Key Principles

1. **Always use design tokens** - Never hardcode values
2. **One primary CTA per section** - Use blue sparingly
3. **Generous whitespace** - Don't crowd elements
4. **Mobile-first** - Test on small screens

## 📖 Full Documentation

See [DESIGN_SYSTEM.md](DESIGN_SYSTEM.md) for complete documentation.
