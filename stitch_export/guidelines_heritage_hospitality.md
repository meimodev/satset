## Brand & Style
This design system is anchored in the concept of "Quiet Luxury." It targets a discerning clientele who values heritage, precision, and understated elegance. The aesthetic draws from **Minimalism** and **Tactile** design movements, focusing on exceptional typography and a restricted, organic palette to evoke a sense of calm and exclusivity. 

The emotional response should be one of "effortless service"—the digital equivalent of a five-star concierge. The UI remains sophisticated and clean, avoiding flashy trends in favor of timeless editorial layouts that prioritize high-density information without sacrificing breathability.

## Layout & Spacing
The layout follows a **Fixed Grid** philosophy with high information density. While the app is "clean," it is not "sparse." 
- Use a 12-column grid for tablet/desktop and a 4-column grid for mobile.
- **Rhythm:** An 8pt baseline grid ensures vertical alignment.
- **High Density:** Padding within components (like list items or cards) should be compact (using `md` or `sm` units) to allow more content per screen, reflecting a professional tool for hospitality management or high-end guest booking.
- **Margins:** Generous outer margins (`xl`) are used only for top-level landing screens to introduce an editorial feel.

## Elevation & Depth
Depth is achieved through **Tonal Layers** rather than heavy shadows.
- **Base:** The Soft Cream neutral color serves as the bottom layer.
- **Surfaces:** Use a slightly lighter "Highlight Cream" (#FFFFFF) or a slightly darker "Paper Taupe" (#F0ECE3) to distinguish cards and containers.
- **Shadows:** When necessary, use ultra-diffused "Ambient Shadows." These should have a 15% opacity tint of the Primary Rich Brown (#4A3728) to ensure they feel like natural light falling on a physical surface.
- **Borders:** Use hairline borders (0.5pt to 1pt) in the Secondary Taupe color to define boundaries without adding visual bulk.

## Components
- **Buttons:** Primary buttons use the Rich Brown background with Cream text. Secondary buttons are outlined in Taupe with a Cream background. Use subtle 100ms transitions for hover states.
- **Input Fields:** Minimalist design with a bottom-only border in Taupe. Upon focus, the label transitions to "Label-Caps" and the border darkens to Rich Brown.
- **Cards:** High-density cards with zero shadow and a fine 1px Taupe border. Content should be tightly packed using Be Vietnam Pro for data points.
- **Chips/Badges:** Small, rectangular tags with 2px radius. Use a Tertiary fill with Primary text for status indicators (e.g., "Confirmed," "Premium").
- **Lists:** Use "Divided Lists" where each row is separated by a fine Taupe line. Ensure high vertical density with 12px padding between items.
- **Hospitality Specifics:** 
    - **Date Pickers:** Use a custom Serif-heavy header for the month/year selection.
    - **Amenity Icons:** Custom, fine-line iconography (1pt stroke) in the Primary Rich Brown.