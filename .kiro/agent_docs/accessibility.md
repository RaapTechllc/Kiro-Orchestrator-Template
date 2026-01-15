# Accessibility Guidelines (WCAG 2.1 AA)

## Core Requirements

### Perceivable
- [ ] Alt text on all images
- [ ] Captions for video content
- [ ] Color contrast 4.5:1 minimum
- [ ] Text resizable to 200%

### Operable
- [ ] All functionality via keyboard
- [ ] No keyboard traps
- [ ] Skip navigation links
- [ ] Focus indicators visible

### Understandable
- [ ] Language declared in HTML
- [ ] Consistent navigation
- [ ] Error messages helpful
- [ ] Labels on form inputs

### Robust
- [ ] Valid HTML
- [ ] ARIA used correctly
- [ ] Works with assistive tech

## Testing
```bash
# Automated testing
npx axe-core

# Manual testing
- Tab through entire page
- Use screen reader (VoiceOver/NVDA)
- Test at 200% zoom
```

## Common Patterns
```tsx
// Accessible button
<button
  aria-label="Close dialog"
  onClick={onClose}
>
  <XIcon aria-hidden="true" />
</button>

// Form with label
<label htmlFor="email">Email</label>
<input id="email" type="email" required />

// Skip link
<a href="#main" className="sr-only focus:not-sr-only">
  Skip to main content
</a>
```

## Color Contrast
- Normal text: 4.5:1 ratio
- Large text (18px+): 3:1 ratio
- UI components: 3:1 ratio
- Use contrast checker tools
