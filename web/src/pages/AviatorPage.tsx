import { Container, Title, Text, Group } from '@mantine/core'
import { IconTrendingUp } from '@tabler/icons-react'

export function AviatorPage() {
  return (
    <Container size="xl" py="xl">
      <Group gap="sm" mb="xl">
        <IconTrendingUp size={32} />
        <Title order={1} c="white" fw={700}>
          Aviator
        </Title>
      </Group>
      <Text c="gray.4" size="lg">
        Aviator crash game coming soon...
      </Text>
    </Container>
  )
}