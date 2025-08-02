import { Container, Title, Text, Group } from '@mantine/core'
import { IconDeviceGamepad } from '@tabler/icons-react'
import { useLocale } from '@/hooks/useLocale'

export function SlotsPage() {
  const { t } = useLocale()
  
  return (
    <Container size="xl" py="xl">
      <Group gap="sm" mb="xl">
        <IconDeviceGamepad size={32} />
        <Title order={1} c="white" fw={700}>
          {t('lobby.slot_machines')}
        </Title>
      </Group>
      <Text c="gray.4" size="lg">
        {t('lobby.slot_description')}
      </Text>
    </Container>
  )
}