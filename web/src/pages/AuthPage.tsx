import { useState } from 'react'
import {
  Container,
  Paper,
  TextInput,
  PasswordInput,
  Button,
  Title,
  Text,
  Anchor,
  Center,
  Box,
  Group,
  Stack,
  Alert,
  Divider
} from '@mantine/core'
import { useForm } from '@mantine/form'
import { IconLock, IconUser, IconAlertCircle, IconDice } from '@tabler/icons-react'
import { useAppStore } from '@/store/useAppStore'
import { motion } from 'framer-motion'

interface LoginForm {
  username: string
  password: string
}

interface RegisterForm {
  username: string
  password: string
  confirmPassword: string
}

export function AuthPage() {
  const [isLogin, setIsLogin] = useState(true)
  const [isLoading, setIsLoading] = useState(false)
  const { sendNUIMessage, error } = useAppStore()

  const loginForm = useForm<LoginForm>({
    initialValues: {
      username: '',
      password: '',
    },
    validate: {
      username: (value) => (!value ? 'Username is required' : null),
      password: (value) => (!value ? 'Password is required' : null),
    },
  })

  const registerForm = useForm<RegisterForm>({
    initialValues: {
      username: '',
      password: '',
      confirmPassword: '',
    },
    validate: {
      username: (value) => {
        if (!value) return 'Username is required'
        if (value.length < 3) return 'Username must be at least 3 characters'
        if (value.length > 20) return 'Username must be less than 20 characters'
        if (!/^[a-zA-Z0-9_]+$/.test(value)) return 'Username can only contain letters, numbers, and underscores'
        return null
      },

      password: (value) => {
        if (!value) return 'Password is required'
        if (value.length < 6) return 'Password must be at least 6 characters'
        return null
      },
      confirmPassword: (value, values) => {
        if (!value) return 'Please confirm your password'
        if (value !== values.password) return 'Passwords do not match'
        return null
      },
    },
  })

  const handleLogin = async (values: LoginForm) => {
    setIsLoading(true)
    try {
      await sendNUIMessage('login', values)
    } catch (error) {
      console.error('Login error:', error)
    } finally {
      setIsLoading(false)
    }
  }

  const handleRegister = async (values: RegisterForm) => {
    setIsLoading(true)
    try {
      const { confirmPassword, ...registerData } = values
      await sendNUIMessage('register', registerData)
    } catch (error) {
      console.error('Registration error:', error)
    } finally {
      setIsLoading(false)
    }
  }

  return (
    <Container size="xs" h="100vh" style={{ display: 'flex', alignItems: 'center' }}>
      <motion.div
        initial={{ opacity: 0, y: 50 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.5 }}
        style={{ width: '100%' }}
      >
        <Paper
          shadow="xl"
          p="xl"
          radius="lg"
          className="glass"
          style={{
            background: 'rgba(26, 31, 54, 0.95)',
            backdropFilter: 'blur(20px)',
            border: '1px solid rgba(43, 133, 227, 0.2)',
          }}
        >
          {/* Header */}
          <Center mb="xl">
            <motion.div
              whileHover={{ scale: 1.05 }}
              whileTap={{ scale: 0.95 }}
            >
              <Group gap="md">
                <Box
                  style={{
                    padding: '12px',
                    borderRadius: '50%',
                    background: 'linear-gradient(135deg, #2b85e3 0%, #1e74cc 100%)',
                    boxShadow: '0 0 20px rgba(43, 133, 227, 0.4)',
                  }}
                >
                  <IconDice size={32} color="white" />
                </Box>
                <div>
                  <Title order={2} c="white" fw={700}>
                    Premium Casino
                  </Title>
                  <Text size="sm" c="gray.4">
                    Your premium gaming destination
                  </Text>
                </div>
              </Group>
            </motion.div>
          </Center>

          {/* Error Alert */}
          {error && (
            <Alert
              icon={<IconAlertCircle size={16} />}
              color="red"
              mb="md"
              variant="filled"
            >
              {error}
            </Alert>
          )}

          {/* Toggle Buttons */}
          <Group grow mb="md">
            <Button
              variant={isLogin ? 'filled' : 'subtle'}
              onClick={() => setIsLogin(true)}
              className="btn-casino"
            >
              Login
            </Button>
            <Button
              variant={!isLogin ? 'filled' : 'subtle'}
              onClick={() => setIsLogin(false)}
              className="btn-casino"
            >
              Register
            </Button>
          </Group>

          <motion.div
            key={isLogin ? 'login' : 'register'}
            initial={{ opacity: 0, x: isLogin ? -20 : 20 }}
            animate={{ opacity: 1, x: 0 }}
            transition={{ duration: 0.3 }}
          >
            {isLogin ? (
              /* Login Form */
              <form onSubmit={loginForm.onSubmit(handleLogin)}>
                <Stack gap="md">
                  <TextInput
                    label="Username"
                    placeholder="Enter your username"
                    leftSection={<IconUser size={16} />}
                    required
                    {...loginForm.getInputProps('username')}
                  />

                  <PasswordInput
                    label="Password"
                    placeholder="Enter your password"
                    leftSection={<IconLock size={16} />}
                    required
                    {...loginForm.getInputProps('password')}
                  />

                  <Button
                    type="submit"
                    size="md"
                    loading={isLoading}
                    className="btn-casino glow-blue"
                    style={{ marginTop: '1rem' }}
                  >
                    Sign In
                  </Button>
                </Stack>
              </form>
            ) : (
              /* Register Form */
              <form onSubmit={registerForm.onSubmit(handleRegister)}>
                <Stack gap="md">
                  <TextInput
                    label="Username"
                    placeholder="Choose a username"
                    leftSection={<IconUser size={16} />}
                    required
                    {...registerForm.getInputProps('username')}
                  />


                  <PasswordInput
                    label="Password"
                    placeholder="Create a password"
                    leftSection={<IconLock size={16} />}
                    required
                    {...registerForm.getInputProps('password')}
                  />

                  <PasswordInput
                    label="Confirm Password"
                    placeholder="Confirm your password"
                    leftSection={<IconLock size={16} />}
                    required
                    {...registerForm.getInputProps('confirmPassword')}
                  />

                  <Button
                    type="submit"
                    size="md"
                    loading={isLoading}
                    className="btn-casino glow-blue"
                    style={{ marginTop: '1rem' }}
                  >
                    Create Account
                  </Button>
                </Stack>
              </form>
            )}
          </motion.div>

          <Divider my="xl" color="dark.4" />

          {/* Footer */}
          <Center>
            <Text size="xs" c="gray.5">
              {isLogin ? "Don't have an account? " : "Already have an account? "}
              <Anchor
                component="button"
                type="button"
                c="blue"
                onClick={() => setIsLogin(!isLogin)}
                fw={500}
              >
                {isLogin ? 'Create one here' : 'Sign in instead'}
              </Anchor>
            </Text>
          </Center>
        </Paper>
      </motion.div>
    </Container>
  )
}