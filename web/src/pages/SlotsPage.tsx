import { Container, Title, Text, Group } from '@mantine/core'
import { IconDeviceGamepad } from '@tabler/icons-react'

export function SlotsPage() {
  return (
    <Container size="xl" py="xl">
      <Group gap="sm" mb="xl">
        <IconDeviceGamepad size={32} />
        <Title order={1} c="white" fw={700}>
          Slot Machines
        </Title>
      </Group>
      <Text c="gray.4" size="lg">
        5 unique themed slot machines coming soon...
      </Text>
    </Container>
  )
}