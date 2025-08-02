import { Container, Title, Text, Group } from '@mantine/core'
import { IconCircle } from '@tabler/icons-react'

export function PlinkoPage() {
  return (
    <Container size="xl" py="xl">
      <Group gap="sm" mb="xl">
        <IconCircle size={32} />
        <Title order={1} c="white" fw={700}>
          Plinko
        </Title>
      </Group>
      <Text c="gray.4" size="lg">
        Plinko game with physics simulation coming soon...
      </Text>
    </Container>
  )
}