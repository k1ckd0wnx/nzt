import { createTheme, MantineColorsTuple } from '@mantine/core'

// Casino Blue Palette - Softer blues for easier viewing
const blue: MantineColorsTuple = [
  '#f0f9ff',  // Very light blue
  '#e0f2fe',  // Light blue
  '#bae6fd',  // Lighter blue
  '#7dd3fc',  // Light blue
  '#38bdf8',  // Medium blue
  '#0ea5e9',  // Primary blue (softer)
  '#0284c7',  // Darker blue
  '#0369a1',  // Dark blue
  '#075985',  // Darker blue
  '#1e3a5f'   // Softer dark blue
]

// Casino Dark Gray Palette - Warmer grays to reduce eye strain
const darkGray: MantineColorsTuple = [
  '#fafafa',  // Warmer white
  '#f5f5f5',  // Warmer light gray
  '#e8e8e8',  // Warmer light gray
  '#d4d4d4',  // Warmer medium light gray
  '#a3a3a3',  // Warmer medium gray
  '#737373',  // Warmer medium dark gray
  '#525252',  // Warmer dark gray
  '#404040',  // Warmer darker gray
  '#262626',  // Warmer very dark gray
  '#171717'   // Warmer almost black
]

export const theme = createTheme({
  primaryColor: 'blue',
  primaryShade: 5,
  colors: {
    blue,
    dark: darkGray,
    gray: darkGray
  },
  fontFamily: 'Inter, system-ui, sans-serif',
  fontFamilyMonospace: 'JetBrains Mono, Monaco, Courier, monospace',
  headings: {
    fontFamily: 'Inter, system-ui, sans-serif',
    fontWeight: '700',
  },
  defaultRadius: 'md',
  cursorType: 'pointer',
  focusRing: 'auto',
  activeClassName: 'mantine-active',
  components: {
    Button: {
      defaultProps: {
        variant: 'filled',
      },
    },
    Card: {
      defaultProps: {
        shadow: 'sm',
        padding: 'lg',
        radius: 'md',
        withBorder: true,
      },
    },
    Modal: {
      defaultProps: {
        centered: true,
        overlayProps: {
          backgroundOpacity: 0.55,
          blur: 3,
        },
      },
    },
    Paper: {
      defaultProps: {
        shadow: 'xs',
        radius: 'md',
        withBorder: true,
      },
    },
  },
})