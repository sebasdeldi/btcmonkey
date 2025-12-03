# Stylesheet Architecture

This document explains the modular CSS architecture of the BTC Play design system.

## 📁 File Structure

```
app/assets/stylesheets/
├── application.css           # Main entry point (imports everything)
├── design_tokens.css         # CSS custom properties (design tokens)
├── components.css            # DEPRECATED - kept for backwards compatibility
│
├── components/               # Component-specific styles
│   ├── alerts.css           # Alert & flash message styles
│   ├── badges.css           # Badge, tag, and status badge styles
│   ├── buttons.css          # All button variants
│   ├── cards.css            # Card component styles
│   ├── forms.css            # Form field styles
│   ├── hero.css             # Hero section styles
│   ├── navigation.css       # Navigation bar styles
│   ├── package_card.css     # Credit package card (app-specific)
│   ├── tables.css           # Table styles
│   ├── transaction.css      # Transaction card styles
│   └── wallet_card.css      # Wallet card (app-specific)
│
└── layout/                   # Layout and utility styles
    ├── base.css             # Reset & base typography
    ├── containers.css       # Container & section layouts
    ├── grid.css             # Grid systems
    └── utilities.css        # Utility classes
```

## 🔗 Component Matching

Each CSS file matches an HTML component partial:

| CSS File | HTML Partial | Purpose |
|----------|--------------|---------|
| `components/buttons.css` | `views/components/_button.html.erb` | Button component |
| `components/cards.css` | `views/components/_card.html.erb` | Card component |
| `components/badges.css` | `views/components/_badge.html.erb`<br>`views/components/_status_badge.html.erb`<br>`views/components/_tag.html.erb` | Badges and tags |
| `components/alerts.css` | `views/components/_alert.html.erb`<br>`views/shared/_flash_messages.html.erb` | Alerts and flash messages |
| `components/forms.css` | `views/components/_form_field.html.erb` | Form inputs |
| `components/navigation.css` | `views/shared/_navigation.html.erb` | Navigation bar |
| `components/hero.css` | `views/components/_hero.html.erb` | Hero sections |
| `components/package_card.css` | `views/components/_package_card.html.erb` | Package cards |
| `components/wallet_card.css` | `views/components/_wallet_card.html.erb` | Wallet display |
| `components/transaction.css` | Transaction views | Transaction details |
| `components/tables.css` | Table views | Data tables |

## 🎯 Benefits

### 1. **Easy to Find Styles**
Need to update button styles? Go to `components/buttons.css`.
Need to update card styles? Go to `components/cards.css`.

### 2. **Better Performance**
- Smaller individual files
- Better browser caching
- Unchanged files stay cached

### 3. **Easier Maintenance**
- Each component is isolated
- Changes don't affect other components
- Easy to debug issues

### 4. **Clear Organization**
- Styles match HTML component structure
- Easy for new developers to understand
- Self-documenting file names

### 5. **Scalability**
- Easy to add new components
- Can remove unused components
- Modular architecture grows with app

## 📖 How It Works

### Import Chain

```
application.css
  ├── design_tokens.css        (CSS variables)
  │
  ├── layout/
  │   ├── base.css            (uses design tokens)
  │   ├── containers.css      (uses design tokens)
  │   ├── grid.css            (uses design tokens)
  │   └── utilities.css       (uses design tokens)
  │
  └── components/
      ├── buttons.css         (uses design tokens)
      ├── cards.css           (uses design tokens)
      ├── badges.css          (uses design tokens)
      └── ...                 (all use design tokens)
```

### Design Token Usage

All component files use design tokens instead of hardcoded values:

**❌ Old Way (Hardcoded):**
```css
.button {
  color: #3b82f6;
  padding: 12px 24px;
  border-radius: 8px;
}
```

**✅ New Way (Design Tokens):**
```css
.btn {
  color: var(--color-primary-blue);
  padding: var(--space-3) var(--space-6);
  border-radius: var(--radius-md);
}
```

## 🛠️ Working with Components

### Adding a New Component

1. **Create HTML partial**
   ```bash
   touch app/views/components/_my_component.html.erb
   ```

2. **Create CSS file**
   ```bash
   touch app/assets/stylesheets/components/my_component.css
   ```

3. **Write styles using design tokens**
   ```css
   /**
    * MY COMPONENT
    * Description of what this component does
    *
    * Matches: app/views/components/_my_component.html.erb
    */

   .my-component {
     background: var(--color-primary-white);
     padding: var(--space-6);
     border-radius: var(--radius-lg);
   }
   ```

4. **Import in application.css**
   ```css
   @import url("components/my_component.css");
   ```

5. **Document in COMPONENTS.md**
   Add full documentation with parameters and examples

### Updating an Existing Component

1. **Find the CSS file**
   - Button styles? → `components/buttons.css`
   - Card styles? → `components/cards.css`
   - Form styles? → `components/forms.css`

2. **Make your changes**
   ```css
   /* components/buttons.css */
   .btn-primary {
     background-color: var(--color-primary-blue);
     /* Your changes here */
   }
   ```

3. **Changes apply everywhere**
   All buttons using `.btn-primary` get updated automatically

### Removing a Component

1. **Delete the CSS file**
   ```bash
   rm app/assets/stylesheets/components/unused_component.css
   ```

2. **Remove import from application.css**
   ```css
   /* Remove this line */
   @import url("components/unused_component.css");
   ```

3. **Delete HTML partial**
   ```bash
   rm app/views/components/_unused_component.html.erb
   ```

## 📝 File Naming Conventions

### CSS Files
- Use lowercase
- Use underscores for multi-word names
- Match HTML partial name
- Examples:
  - `buttons.css` → `_button.html.erb`
  - `package_card.css` → `_package_card.html.erb`
  - `wallet_card.css` → `_wallet_card.html.erb`

### CSS Classes
- Use kebab-case
- Prefix with component name
- Examples:
  - `.btn`, `.btn-primary`, `.btn-secondary`
  - `.card`, `.card-header`, `.card-body`
  - `.package-card`, `.package-header`, `.package-body`

## 🎨 Component Categories

### UI Components (Generic)
These can be used in any project:
- Buttons
- Cards
- Badges & Tags
- Alerts
- Forms
- Tables
- Navigation
- Hero

### App-Specific Components
These are specific to BTC Play:
- Package Card
- Wallet Card
- Transaction Card

### Layout
Not components, but layout utilities:
- Base (reset, typography)
- Containers (sections, max-widths)
- Grid (responsive grids)
- Utilities (spacing, alignment)

## 🔍 Finding Styles

### "Where is the style for X?"

| Element | File Location |
|---------|---------------|
| Button | `components/buttons.css` |
| Card | `components/cards.css` |
| Form input | `components/forms.css` |
| Badge/Tag | `components/badges.css` |
| Alert | `components/alerts.css` |
| Navigation | `components/navigation.css` |
| Table | `components/tables.css` |
| Package card | `components/package_card.css` |
| Wallet display | `components/wallet_card.css` |
| Grid layout | `layout/grid.css` |
| Container | `layout/containers.css` |
| Utility class | `layout/utilities.css` |
| Typography | `layout/base.css` |
| Design tokens | `design_tokens.css` |

## 📊 File Sizes

Modular structure keeps files small and focused:

```
design_tokens.css    ~5KB   (CSS variables only)
components/buttons.css      ~2KB
components/cards.css        ~3KB
components/badges.css       ~1.5KB
components/forms.css        ~2KB
components/navigation.css   ~2.5KB
components/package_card.css ~2KB
components/wallet_card.css  ~1KB
layout/base.css             ~2KB
layout/containers.css       ~1.5KB
layout/grid.css             ~1KB
layout/utilities.css        ~2KB
```

Total: ~25KB (vs. 50KB+ monolithic file)

## 🚀 Performance Benefits

### Browser Caching
- Unchanged component files stay cached
- Only modified files are re-downloaded
- Faster subsequent page loads

### Parallel Downloads
- Browsers can download multiple CSS files in parallel
- Faster initial page load

### Selective Loading (Future)
- Can conditionally load only needed components
- Reduce CSS payload for specific pages

## 🔄 Migration from Old Structure

### Old Structure (Deprecated)
```
app/assets/stylesheets/
├── application.css (everything in one file - 50KB+)
└── components.css  (everything in one file - 30KB+)
```

### New Structure (Current)
```
app/assets/stylesheets/
├── application.css (imports only - 3KB)
├── design_tokens.css
├── components/
│   ├── buttons.css
│   ├── cards.css
│   └── ...
└── layout/
    ├── base.css
    ├── containers.css
    └── ...
```

### Backwards Compatibility

The old `components.css` file is kept for backwards compatibility but is deprecated. New code should use the modular structure.

## 📚 Related Documentation

- **[DESIGN_SYSTEM.md](DESIGN_SYSTEM.md)** - Complete design system guide
- **[COMPONENTS.md](COMPONENTS.md)** - HTML component library
- **[DESIGN_SYSTEM_QUICK_START.md](DESIGN_SYSTEM_QUICK_START.md)** - Quick reference
- **[DESIGN_SYSTEM_README.md](DESIGN_SYSTEM_README.md)** - Overview and getting started

## ✅ Best Practices

### DO ✅

- Keep component files focused on one component
- Use design tokens for all values
- Match CSS file name to HTML partial name
- Add header comments explaining what each file is for
- Import new component files in application.css
- Document new components in COMPONENTS.md

### DON'T ❌

- Don't hardcode values (use tokens)
- Don't put multiple component styles in one file
- Don't use inline styles (except dynamic values)
- Don't create duplicate styles
- Don't forget to import new files
- Don't skip documentation

## 🎯 Quick Reference

### Creating a Component

1. Create HTML partial: `app/views/components/_name.html.erb`
2. Create CSS file: `app/assets/stylesheets/components/name.css`
3. Import in application.css: `@import url("components/name.css");`
4. Document in COMPONENTS.md

### Updating a Component

1. Find CSS file in `components/` directory
2. Make changes using design tokens
3. Changes apply everywhere automatically

### Finding Styles

1. Check component name
2. Look in `components/[name].css`
3. Or search in application.css comments

---

**Version:** 2.0.0 (Modular Architecture)
**Previous Version:** 1.0.0 (Monolithic)
**Last Updated:** December 2024
