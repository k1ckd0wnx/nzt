import { createTheme, MantineColorsTuple } from '@mantine/core'

const blue: MantineColorsTuple = [
  '#e8f4fd',
  '#d1e6fa',
  '#a3ccf4',
  '#72b1ed',
  '#4c9ae7',
  '#378ce4',
  '#2b85e3',
  '#1e74cc',
  '#1868b7',
  '#0f5ba1'
]

export const theme = createTheme({
  primaryColor: 'blue',
  primaryShade: 6,
  colors: {
    blue,
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