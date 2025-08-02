import { useState } from 'react'
import {
  Container,
  Grid,
  Card,
  Text,
  Title,
  Button,
  NumberInput,
  Group,
  Stack,
  Paper,
  ThemeIcon,
  Flex,
  Alert,
  Badge,
  Divider,
  SimpleGrid,
  Progress
} from '@mantine/core'
import {
  IconWallet,
  IconDownload,
  IconUpload,
  IconCreditCard,
  IconBuildingBank,
  IconInfoCircle,
  IconShieldCheck,
  IconClock,
  IconTrendingUp
} from '@tabler/icons-react'
import { useForm } from '@mantine/form'
import { useAppStore } from '@/store/useAppStore'
import { motion } from 'framer-motion'

interface TransactionForm {
  amount: number
}

export function BankingPage() {
  const [isDepositing, setIsDepositing] = useState(true)
  const [isLoading, setIsLoading] = useState(false)
  const { user, sendNUIMessage } = useAppStore()

  const depositForm = useForm<TransactionForm>({
    initialValues: { amount: 100 },
    validate: {
      amount: (value) => {
        if (!value || value <= 0) return 'Amount must be greater than 0'
        if (value > 100000) return 'Maximum deposit is $100,000'
        return null
      },
    },
  })

  const withdrawForm = useForm<TransactionForm>({
    initialValues: { amount: 100 },
    validate: {
      amount: (value) => {
        if (!value || value <= 0) return 'Amount must be greater than 0'
        if (value > (user?.balance || 0)) return 'Insufficient balance'
        if (value > 50000) return 'Maximum withdrawal is $50,000'
        return null
      },
    },
  })

  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD',
      minimumFractionDigits: 0,
      maximumFractionDigits: 0,
    }).format(amount)
  }

  const handleDeposit = async (values: TransactionForm) => {
    setIsLoading(true)
    try {
      await sendNUIMessage('deposit', { amount: values.amount })
      depositForm.reset()
    } catch (error) {
      console.error('Deposit error:', error)
    } finally {
      setIsLoading(false)
    }
  }

  const handleWithdraw = async (values: TransactionForm) => {
    setIsLoading(true)
    try {
      await sendNUIMessage('withdraw', { amount: values.amount })
      withdrawForm.reset()
    } catch (error) {
      console.error('Withdrawal error:', error)
    } finally {
      setIsLoading(false)
    }
  }

  const quickAmounts = [100, 500, 1000, 5000, 10000]

  const features = [
    {
      icon: <IconShieldCheck size={24} />,
      title: 'Secure Transactions',
      description: 'All transactions are encrypted and secure',
      color: 'green',
    },
    {
      icon: <IconClock size={24} />,
      title: 'Instant Processing',
      description: 'Deposits and withdrawals process instantly',
      color: 'blue',
    },
    {
      icon: <IconBuildingBank size={24} />,
      title: 'Bank Integration',
      description: 'Direct connection to your bank account',
      color: 'teal',
    },
  ]

  return (
    <Container size="lg" py="xl">
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.5 }}
      >
        <Stack gap="xl">
          {/* Header */}
          <div>
            <Title order={1} c="white" fw={700} mb="xs">
              <Group gap="sm">
                <IconWallet size={32} />
                Banking
              </Group>
            </Title>
            <Text size="lg" c="gray.4">
              Manage your casino balance with secure deposits and withdrawals.
            </Text>
          </div>

          {/* Balance Overview */}
          <Paper
            p="xl"
            radius="lg"
            className="glass glow-blue"
            style={{
              background: 'linear-gradient(135deg, rgba(43, 133, 227, 0.1) 0%, rgba(26, 31, 54, 0.9) 100%)',
              border: '1px solid rgba(43, 133, 227, 0.3)',
            }}
          >
            <Group justify="space-between" align="center">
              <div>
                <Text size="sm" c="gray.4" fw={500} tt="uppercase" mb="xs">
                  Casino Balance
                </Text>
                <Title order={1} c="white" fw={700} className="count-up">
                  {formatCurrency(user?.balance || 0)}
                </Title>
              </div>
              <ThemeIcon
                size="xl"
                radius="md"
                variant="gradient"
                gradient={{ from: 'blue', to: 'cyan' }}
              >
                <IconCreditCard size={32} />
              </ThemeIcon>
            </Group>
          </Paper>

          <Grid>
            {/* Transaction Form */}
            <Grid.Col span={{ base: 12, md: 8 }}>
              {/* Toggle Buttons */}
              <Group grow mb="lg">
                <Button
                  variant={isDepositing ? 'filled' : 'subtle'}
                  leftSection={<IconDownload size={16} />}
                  onClick={() => setIsDepositing(true)}
                  className="btn-casino"
                >
                  Deposit
                </Button>
                <Button
                  variant={!isDepositing ? 'filled' : 'subtle'}
                  leftSection={<IconUpload size={16} />}
                  onClick={() => setIsDepositing(false)}
                  className="btn-casino"
                >
                  Withdraw
                </Button>
              </Group>

              <motion.div
                key={isDepositing ? 'deposit' : 'withdraw'}
                initial={{ opacity: 0, x: isDepositing ? -20 : 20 }}
                animate={{ opacity: 1, x: 0 }}
                transition={{ duration: 0.3 }}
              >
                <Card
                  shadow="lg"
                  p="xl"
                  radius="lg"
                  className="glass"
                  style={{
                    background: 'rgba(26, 31, 54, 0.9)',
                    border: '1px solid rgba(255, 255, 255, 0.1)',
                  }}
                >
                  {isDepositing ? (
                    /* Deposit Form */
                    <form onSubmit={depositForm.onSubmit(handleDeposit)}>
                      <Stack gap="lg">
                        <div>
                          <Title order={3} c="white" mb="md">
                            <Group gap="sm">
                              <IconDownload size={24} color="var(--mantine-color-green-6)" />
                              Deposit Funds
                            </Group>
                          </Title>
                          <Text c="gray.4" mb="lg">
                            Transfer money from your bank account to your casino balance.
                          </Text>
                        </div>

                        <NumberInput
                          label="Deposit Amount"
                          placeholder="Enter amount to deposit"
                          min={1}
                          max={100000}
                          size="lg"
                          leftSection="$"
                          {...depositForm.getInputProps('amount')}
                        />

                        {/* Quick Amount Buttons */}
                        <div>
                          <Text size="sm" c="gray.4" mb="sm">
                            Quick amounts:
                          </Text>
                          <SimpleGrid cols={5} spacing="sm">
                            {quickAmounts.map((amount) => (
                              <Button
                                key={amount}
                                variant="subtle"
                                size="sm"
                                onClick={() => depositForm.setFieldValue('amount', amount)}
                                className="btn-casino"
                              >
                                {formatCurrency(amount)}
                              </Button>
                            ))}
                          </SimpleGrid>
                        </div>

                        <Alert icon={<IconInfoCircle size={16} />} color="blue" variant="light">
                          <Text size="sm">
                            <strong>Daily Limit:</strong> $100,000 • <strong>Processing:</strong> Instant
                          </Text>
                        </Alert>

                        <Button
                          type="submit"
                          size="lg"
                          loading={isLoading}
                          leftSection={<IconDownload size={18} />}
                          className="btn-casino glow-green"
                          color="green"
                        >
                          Deposit {formatCurrency(depositForm.values.amount || 0)}
                        </Button>
                      </Stack>
                    </form>
                  ) : (
                    /* Withdraw Form */
                    <form onSubmit={withdrawForm.onSubmit(handleWithdraw)}>
                      <Stack gap="lg">
                        <div>
                          <Title order={3} c="white" mb="md">
                            <Group gap="sm">
                              <IconUpload size={24} color="var(--mantine-color-orange-6)" />
                              Withdraw Funds
                            </Group>
                          </Title>
                          <Text c="gray.4" mb="lg">
                            Transfer money from your casino balance to your bank account.
                          </Text>
                        </div>

                        <NumberInput
                          label="Withdrawal Amount"
                          placeholder="Enter amount to withdraw"
                          min={1}
                          max={user?.balance || 0}
                          size="lg"
                          leftSection="$"
                          {...withdrawForm.getInputProps('amount')}
                        />

                        {/* Quick Amount Buttons */}
                        <div>
                          <Text size="sm" c="gray.4" mb="sm">
                            Quick amounts:
                          </Text>
                          <SimpleGrid cols={5} spacing="sm">
                            {quickAmounts
                              .filter((amount) => amount <= (user?.balance || 0))
                              .map((amount) => (
                                <Button
                                  key={amount}
                                  variant="subtle"
                                  size="sm"
                                  onClick={() => withdrawForm.setFieldValue('amount', amount)}
                                  className="btn-casino"
                                >
                                  {formatCurrency(amount)}
                                </Button>
                              ))}
                            <Button
                              variant="subtle"
                              size="sm"
                              onClick={() => withdrawForm.setFieldValue('amount', user?.balance || 0)}
                              className="btn-casino"
                            >
                              All
                            </Button>
                          </SimpleGrid>
                        </div>

                        <Alert icon={<IconInfoCircle size={16} />} color="orange" variant="light">
                          <Text size="sm">
                            <strong>Daily Limit:</strong> $50,000 • <strong>Available:</strong> {formatCurrency(user?.balance || 0)}
                          </Text>
                        </Alert>

                        <Button
                          type="submit"
                          size="lg"
                          loading={isLoading}
                          leftSection={<IconUpload size={18} />}
                          className="btn-casino glow-orange"
                          color="orange"
                        >
                          Withdraw {formatCurrency(withdrawForm.values.amount || 0)}
                        </Button>
                      </Stack>
                    </form>
                  )}
                </Card>
              </motion.div>
            </Grid.Col>

            {/* Features and Info */}
            <Grid.Col span={{ base: 12, md: 4 }}>
              <Stack gap="lg">
                <Title order={3} c="white" fw={600}>
                  Features
                </Title>

                {features.map((feature, index) => (
                  <motion.div
                    key={feature.title}
                    initial={{ opacity: 0, y: 20 }}
                    animate={{ opacity: 1, y: 0 }}
                    transition={{ duration: 0.5, delay: 0.2 + index * 0.1 }}
                  >
                    <Paper
                      p="md"
                      radius="md"
                      className="glass"
                      style={{
                        background: 'rgba(26, 31, 54, 0.6)',
                        border: '1px solid rgba(255, 255, 255, 0.1)',
                      }}
                    >
                      <Group gap="md">
                        <ThemeIcon
                          size="lg"
                          radius="md"
                          color={feature.color}
                          variant="light"
                        >
                          {feature.icon}
                        </ThemeIcon>
                        <div style={{ flex: 1 }}>
                          <Text size="sm" fw={600} c="white">
                            {feature.title}
                          </Text>
                          <Text size="xs" c="gray.5">
                            {feature.description}
                          </Text>
                        </div>
                      </Group>
                    </Paper>
                  </motion.div>
                ))}

                <Divider color="dark.4" />

                {/* Transaction Limits */}
                <motion.div
                  initial={{ opacity: 0, y: 20 }}
                  animate={{ opacity: 1, y: 0 }}
                  transition={{ duration: 0.5, delay: 0.5 }}
                >
                  <Title order={4} c="white" mb="md">
                    Transaction Limits
                  </Title>
                  
                  <Paper
                    p="md"
                    radius="md"
                    className="glass"
                    style={{
                      background: 'rgba(26, 31, 54, 0.6)',
                      border: '1px solid rgba(255, 255, 255, 0.1)',
                    }}
                  >
                    <Stack gap="sm">
                      <Flex justify="space-between">
                        <Text size="sm" c="gray.4">Deposit Limit:</Text>
                        <Text size="sm" c="white" fw={500}>$100,000/day</Text>
                      </Flex>
                      <Flex justify="space-between">
                        <Text size="sm" c="gray.4">Withdrawal Limit:</Text>
                        <Text size="sm" c="white" fw={500}>$50,000/day</Text>
                      </Flex>
                      <Flex justify="space-between">
                        <Text size="sm" c="gray.4">Minimum Amount:</Text>
                        <Text size="sm" c="white" fw={500}>$1</Text>
                      </Flex>
                    </Stack>
                  </Paper>
                </motion.div>

                {/* Account Stats */}
                <motion.div
                  initial={{ opacity: 0, y: 20 }}
                  animate={{ opacity: 1, y: 0 }}
                  transition={{ duration: 0.5, delay: 0.6 }}
                >
                  <Title order={4} c="white" mb="md">
                    Account Summary
                  </Title>
                  
                  <Paper
                    p="md"
                    radius="md"
                    className="glass"
                    style={{
                      background: 'rgba(26, 31, 54, 0.6)',
                      border: '1px solid rgba(255, 255, 255, 0.1)',
                    }}
                  >
                    <Stack gap="sm">
                      <Flex justify="space-between">
                        <Text size="sm" c="gray.4">Total Deposited:</Text>
                        <Text size="sm" c="green" fw={500}>
                          {formatCurrency(user?.totalDeposited || 0)}
                        </Text>
                      </Flex>
                      <Flex justify="space-between">
                        <Text size="sm" c="gray.4">Total Withdrawn:</Text>
                        <Text size="sm" c="orange" fw={500}>
                          {formatCurrency(user?.totalWithdrawn || 0)}
                        </Text>
                      </Flex>
                      <Flex justify="space-between">
                        <Text size="sm" c="gray.4">Net Deposit:</Text>
                        <Text size="sm" c="blue" fw={500}>
                          {formatCurrency((user?.totalDeposited || 0) - (user?.totalWithdrawn || 0))}
                        </Text>
                      </Flex>
                    </Stack>
                  </Paper>
                </motion.div>
              </Stack>
            </Grid.Col>
          </Grid>
        </Stack>
      </motion.div>
    </Container>
  )
}