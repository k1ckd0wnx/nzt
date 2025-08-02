import { Container, Title, Text, Group } from '@mantine/core'
import { IconBomb } from '@tabler/icons-react'

export function MinesPage() {
  return (
    <Container size="xl" py="xl">
      <Group gap="sm" mb="xl">
        <IconBomb size={32} />
        <Title order={1} c="white" fw={700}>
          Mines
        </Title>
      </Group>
      <Text c="gray.4" size="lg">
        Mines grid game coming soon...
      </Text>
    </Container>
  )
}