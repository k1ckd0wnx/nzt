import { Container, Title, Text, Group } from '@mantine/core'
import { IconTrendingUp } from '@tabler/icons-react'
import { useLocale } from '@/hooks/useLocale'

export function AviatorPage() {
  const { t } = useLocale()
  
  return (
    <Container size="xl" py="xl">
      <Group gap="sm" mb="xl">
        <IconTrendingUp size={32} />
        <Title order={1} c="white" fw={700}>
          {t('nav.aviator')}
        </Title>
      </Group>
      <Text c="gray.4" size="lg">
        {t('lobby.aviator_description')}
      </Text>
    </Container>
  )
}