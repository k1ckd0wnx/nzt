import { createTheme, MantineColorsTuple } from '@mantine/core'

// Casino Blue Palette - Clean blues from light to dark
const blue: MantineColorsTuple = [
  '#f0f9ff',  // Very light blue
  '#e0f2fe',  // Light blue
  '#bae6fd',  // Lighter blue
  '#7dd3fc',  // Light blue
  '#38bdf8',  // Medium blue
  '#0ea5e9',  // Primary blue
  '#0284c7',  // Darker blue
  '#0369a1',  // Dark blue
  '#075985',  // Darker blue
  '#0c4a6e'   // Very dark blue
]

// Casino Dark Gray Palette - Clean grays from light to dark
const darkGray: MantineColorsTuple = [
  '#f8fafc',  // Almost white
  '#f1f5f9',  // Very light gray
  '#e2e8f0',  // Light gray
  '#cbd5e1',  // Medium light gray
  '#94a3b8',  // Medium gray
  '#64748b',  // Medium dark gray
  '#475569',  // Dark gray
  '#334155',  // Darker gray
  '#1e293b',  // Very dark gray
  '#0f172a'   // Almost black
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