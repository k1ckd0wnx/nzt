import { useState, useRef, useEffect, useCallback } from 'react'
import {
  Container,
  Title,
  Text,
  Button,
  NumberInput,
  Group,
  Stack,
  Paper,
  Badge,
  Grid,
  Center,
  Box,
  ActionIcon,
  Tooltip
} from '@mantine/core'
import { IconPlayerPlay, IconMinus, IconPlus, IconCoins, IconTrophy } from '@tabler/icons-react'
import { useAppStore } from '@/store/useAppStore'
import { useLocale } from '@/hooks/useLocale'
import { motion, AnimatePresence } from 'framer-motion'

interface Ball {
  id: number
  x: number
  y: number
  vx: number
  vy: number
  radius: number
  color: string
  trail: { x: number; y: number }[]
}

interface Peg {
  x: number
  y: number
  radius: number
}

const MULTIPLIERS = [100, 26, 9, 4, 2, 1.5, 1, 0.5, 0.2, 0.5, 1, 1.5, 2, 4, 9, 26, 100]
const ROWS = 16
const PEG_RADIUS = 3
const BALL_RADIUS = 5
const GRAVITY = 0.25
const BOUNCE = 0.6
const FRICTION = 0.998
const CANVAS_WIDTH = 700
const CANVAS_HEIGHT = 600

export function PlinkoPage() {
  const { user, sendNUIMessage } = useAppStore()
  const { t } = useLocale()
  const canvasRef = useRef<HTMLCanvasElement>(null)
  const animationFrameRef = useRef<number>()
  
  const [betAmount, setBetAmount] = useState(10)
  const [isPlaying, setIsPlaying] = useState(false)
  const [balls, setBalls] = useState<Ball[]>([])
  const [pegs, setPegs] = useState<Peg[]>([])
  const [lastWin, setLastWin] = useState<number | null>(null)
  const [ballCount, setBallCount] = useState(0)

  // Initialize pegs with better distribution
  useEffect(() => {
    const newPegs: Peg[] = []
    const width = CANVAS_WIDTH
    const height = CANVAS_HEIGHT
    const pegSpacing = width / (ROWS + 2)
    const rowHeight = (height - 180) / ROWS

    for (let row = 0; row < ROWS; row++) {
      const pegsInRow = row + 3
      const startX = (width - (pegsInRow - 1) * pegSpacing) / 2
      
      for (let col = 0; col < pegsInRow; col++) {
        newPegs.push({
          x: startX + col * pegSpacing,
          y: 80 + row * rowHeight,
          radius: PEG_RADIUS
        })
      }
    }
    
    setPegs(newPegs)
  }, [])

  // Enhanced animation loop with better graphics
  useEffect(() => {
    const canvas = canvasRef.current
    const ctx = canvas?.getContext('2d')
    if (!canvas || !ctx) return

    // Enable hardware acceleration
    ctx.imageSmoothingEnabled = true
    ctx.imageSmoothingQuality = 'high'

    const animate = () => {
      // Clear canvas with gradient background
      const gradient = ctx.createLinearGradient(0, 0, 0, canvas.height)
      gradient.addColorStop(0, 'rgba(15, 23, 42, 0.95)')
      gradient.addColorStop(1, 'rgba(30, 41, 59, 0.95)')
      ctx.fillStyle = gradient
      ctx.fillRect(0, 0, canvas.width, canvas.height)

      // Draw enhanced pegs with glow effect
      pegs.forEach(peg => {
        // Glow effect
        ctx.shadowColor = '#3b82f6'
        ctx.shadowBlur = 10
        ctx.shadowOffsetX = 0
        ctx.shadowOffsetY = 0
        
        // Peg gradient
        const pegGradient = ctx.createRadialGradient(peg.x, peg.y, 0, peg.x, peg.y, peg.radius * 2)
        pegGradient.addColorStop(0, '#60a5fa')
        pegGradient.addColorStop(0.7, '#3b82f6')
        pegGradient.addColorStop(1, '#1e40af')
        
        ctx.beginPath()
        ctx.arc(peg.x, peg.y, peg.radius, 0, Math.PI * 2)
        ctx.fillStyle = pegGradient
        ctx.fill()
        
        // Peg border
        ctx.shadowBlur = 0
        ctx.strokeStyle = '#1e40af'
        ctx.lineWidth = 1.5
        ctx.stroke()
      })

      // Reset shadow for other elements
      ctx.shadowBlur = 0

      // Draw enhanced multiplier zones
      const zoneWidth = canvas.width / MULTIPLIERS.length
      MULTIPLIERS.forEach((multiplier, index) => {
        const x = index * zoneWidth
        const y = canvas.height - 70
        
        // Zone gradient background
        const zoneGradient = ctx.createLinearGradient(x, y, x, y + 70)
        if (multiplier >= 100) {
          zoneGradient.addColorStop(0, 'rgba(34, 197, 94, 0.3)')
          zoneGradient.addColorStop(1, 'rgba(34, 197, 94, 0.6)')
        } else if (multiplier >= 10) {
          zoneGradient.addColorStop(0, 'rgba(59, 130, 246, 0.3)')
          zoneGradient.addColorStop(1, 'rgba(59, 130, 246, 0.6)')
        } else {
          zoneGradient.addColorStop(0, 'rgba(156, 163, 175, 0.3)')
          zoneGradient.addColorStop(1, 'rgba(156, 163, 175, 0.6)')
        }
        
        ctx.fillStyle = zoneGradient
        ctx.fillRect(x, y, zoneWidth, 70)
        
        // Zone border
        ctx.strokeStyle = multiplier >= 100 ? '#22c55e' : 
                         multiplier >= 10 ? '#3b82f6' : '#9ca3af'
        ctx.lineWidth = 2
        ctx.strokeRect(x, y, zoneWidth, 70)
        
        // Multiplier text with better styling
        const textColor = multiplier >= 100 ? '#22c55e' : 
                         multiplier >= 10 ? '#3b82f6' : '#9ca3af'
        ctx.fillStyle = textColor
        ctx.font = 'bold 14px Inter'
        ctx.textAlign = 'center'
        ctx.textBaseline = 'middle'
        
        // Text shadow for better visibility
        ctx.shadowColor = 'rgba(0, 0, 0, 0.8)'
        ctx.shadowBlur = 2
        ctx.fillText(`${multiplier}x`, x + zoneWidth / 2, y + 35)
        ctx.shadowBlur = 0
      })

      // Update and draw balls with enhanced physics
      setBalls(prevBalls => {
        const updatedBalls = prevBalls.map(ball => {
          // Enhanced physics
          ball.vy += GRAVITY
          ball.x += ball.vx
          ball.y += ball.vy
          ball.vx *= FRICTION
          ball.vy *= FRICTION

          // Add to trail with time-based fading
          ball.trail.push({ x: ball.x, y: ball.y })
          if (ball.trail.length > 12) ball.trail.shift()

          // Enhanced collision with pegs
          pegs.forEach(peg => {
            const dx = ball.x - peg.x
            const dy = ball.y - peg.y
            const distance = Math.sqrt(dx * dx + dy * dy)
            
            if (distance < ball.radius + peg.radius) {
              const angle = Math.atan2(dy, dx)
              const targetX = peg.x + Math.cos(angle) * (peg.radius + ball.radius)
              const targetY = peg.y + Math.sin(angle) * (peg.radius + ball.radius)
              
              ball.x = targetX
              ball.y = targetY
              
              // More realistic bounce with randomness
              const bounceStrength = BOUNCE * (0.8 + Math.random() * 0.4)
              ball.vx = Math.cos(angle) * bounceStrength * 3 + (Math.random() - 0.5) * 0.8
              ball.vy = Math.sin(angle) * bounceStrength * 3 + Math.random() * 0.5
            }
          })

          // Enhanced wall collision
          if (ball.x < ball.radius || ball.x > canvas.width - ball.radius) {
            ball.vx *= -BOUNCE
            ball.x = ball.x < ball.radius ? ball.radius : canvas.width - ball.radius
            // Add some vertical randomness on wall hits
            ball.vy += (Math.random() - 0.5) * 0.3
          }

          // Check if ball reached bottom
          if (ball.y > canvas.height - 90) {
            const zoneIndex = Math.floor(ball.x / (canvas.width / MULTIPLIERS.length))
            const clampedIndex = Math.max(0, Math.min(MULTIPLIERS.length - 1, zoneIndex))
            const winAmount = betAmount * MULTIPLIERS[clampedIndex]
            
            setLastWin(winAmount)
            
            // Send result to server
            sendNUIMessage('plinkoResult', {
              betAmount,
              multiplier: MULTIPLIERS[clampedIndex],
              winAmount,
              ballId: ball.id
            })

            return null // Remove ball
          }

          return ball
        }).filter(Boolean) as Ball[]

        // Check if all balls are done
        if (prevBalls.length > 0 && updatedBalls.length === 0) {
          setIsPlaying(false)
        }

        return updatedBalls
      })

      // Draw enhanced balls with glow and trails
      balls.forEach(ball => {
        // Draw enhanced trail with gradient
        if (ball.trail.length > 1) {
          ctx.strokeStyle = '#f59e0b'
          ctx.lineWidth = 3
          ctx.lineCap = 'round'
          ctx.lineJoin = 'round'
          
          ctx.beginPath()
          ball.trail.forEach((point, index) => {
            const opacity = index / ball.trail.length
            ctx.globalAlpha = opacity * 0.6
            
            if (index === 0) {
              ctx.moveTo(point.x, point.y)
            } else {
              ctx.lineTo(point.x, point.y)
            }
          })
          ctx.stroke()
          ctx.globalAlpha = 1
        }

        // Draw ball with enhanced glow effect
        ctx.shadowColor = '#f59e0b'
        ctx.shadowBlur = 15
        
        // Ball gradient
        const ballGradient = ctx.createRadialGradient(
          ball.x - ball.radius * 0.3, 
          ball.y - ball.radius * 0.3, 
          0, 
          ball.x, 
          ball.y, 
          ball.radius * 1.5
        )
        ballGradient.addColorStop(0, '#fbbf24')
        ballGradient.addColorStop(0.6, '#f59e0b')
        ballGradient.addColorStop(1, '#d97706')
        
        ctx.beginPath()
        ctx.arc(ball.x, ball.y, ball.radius, 0, Math.PI * 2)
        ctx.fillStyle = ballGradient
        ctx.fill()
        
        // Ball border
        ctx.shadowBlur = 0
        ctx.strokeStyle = '#ffffff'
        ctx.lineWidth = 2
        ctx.stroke()
        
        // Ball highlight
        ctx.beginPath()
        ctx.arc(ball.x - ball.radius * 0.3, ball.y - ball.radius * 0.3, ball.radius * 0.3, 0, Math.PI * 2)
        ctx.fillStyle = 'rgba(255, 255, 255, 0.6)'
        ctx.fill()
      })

      animationFrameRef.current = requestAnimationFrame(animate)
    }

    animate()

    return () => {
      if (animationFrameRef.current) {
        cancelAnimationFrame(animationFrameRef.current)
      }
    }
  }, [balls, pegs, betAmount, sendNUIMessage])

  const dropBall = useCallback(() => {
    if (isPlaying || !user) return
    
    setIsPlaying(true)
    setLastWin(null)

    const newBall: Ball = {
      id: Date.now() + ballCount,
      x: CANVAS_WIDTH / 2 + (Math.random() - 0.5) * 30,
      y: 15,
      vx: (Math.random() - 0.5) * 0.3,
      vy: 0.2,
      radius: BALL_RADIUS,
      color: '#f59e0b',
      trail: []
    }

    setBalls([newBall])
    setBallCount(prev => prev + 1)

    // Send bet to server
    sendNUIMessage('plinkoBet', { betAmount })
  }, [isPlaying, user, betAmount, ballCount, sendNUIMessage])

  const adjustBet = (change: number) => {
    setBetAmount(prev => Math.max(10, Math.min(5000, prev + change)))
  }

  if (!user) {
    return (
      <Container size="xl" py="xl">
        <Center h="60vh">
          <Text c="dimmed">Please log in to play Plinko</Text>
        </Center>
      </Container>
    )
  }

  return (
    <Container size="xl" py="md">
      <Stack gap="md">
        {/* Header */}
        <Group justify="space-between" align="center">
          <div>
            <Title order={2} c="white" fw={700}>
              🔴 {t('plinko.title')}
            </Title>
            <Text c="dimmed" size="sm">
              {t('plinko.subtitle')}
            </Text>
          </div>
          <Group gap="md">
            <Text c="dimmed" size="sm">{t('nav.balance')}:</Text>
            <Badge size="lg" color="blue" variant="filled">
              ${parseFloat(user.balance).toLocaleString()}
            </Badge>
          </Group>
        </Group>

        <Grid>
          {/* Game Controls */}
          <Grid.Col span={{ base: 12, md: 3 }}>
            <Paper p="md" bg="dark.7" radius="md">
              <Stack gap="md">
                <div>
                  <Text size="sm" c="dimmed" mb="xs">{t('games.bet_amount')}</Text>
                  <Group gap="xs">
                    <ActionIcon 
                      variant="filled" 
                      color="blue" 
                      onClick={() => adjustBet(-10)}
                      disabled={betAmount <= 10}
                    >
                      <IconMinus size={16} />
                    </ActionIcon>
                    <NumberInput
                      value={betAmount}
                      onChange={(value) => setBetAmount(Number(value) || 10)}
                      min={10}
                      max={5000}
                      size="sm"
                      styles={{ input: { textAlign: 'center' } }}
                      flex={1}
                    />
                    <ActionIcon 
                      variant="filled" 
                      color="blue" 
                      onClick={() => adjustBet(10)}
                      disabled={betAmount >= 5000}
                    >
                      <IconPlus size={16} />
                    </ActionIcon>
                  </Group>
                </div>

                <Group gap="xs">
                  <Button 
                    size="xs" 
                    variant="outline" 
                    onClick={() => setBetAmount(10)}
                  >
                    Min
                  </Button>
                  <Button 
                    size="xs" 
                    variant="outline" 
                    onClick={() => setBetAmount(Math.floor(parseFloat(user.balance) / 2))}
                  >
                    1/2
                  </Button>
                  <Button 
                    size="xs" 
                    variant="outline" 
                    onClick={() => setBetAmount(Math.floor(parseFloat(user.balance)))}
                  >
                    Max
                  </Button>
                </Group>

                <Button
                  fullWidth
                  size="lg"
                  onClick={dropBall}
                  disabled={isPlaying || betAmount > parseFloat(user.balance)}
                  leftSection={<IconPlayerPlay size={18} />}
                  gradient={{ from: 'blue', to: 'cyan' }}
                  variant="gradient"
                  className="btn-casino"
                >
                  {isPlaying ? t('plinko.dropping') : t('games.drop_ball')}
                </Button>

                {lastWin && (
                  <motion.div
                    initial={{ scale: 0.8, opacity: 0 }}
                    animate={{ scale: 1, opacity: 1 }}
                    transition={{ duration: 0.3 }}
                  >
                    <Paper p="md" bg="green.8" radius="md">
                      <Group justify="center" gap="xs">
                        <IconTrophy size={20} color="#22c55e" />
                        <div>
                          <Text size="sm" c="green" ta="center">You Won!</Text>
                          <Text size="lg" fw={700} c="green" ta="center">
                            ${lastWin.toLocaleString()}
                          </Text>
                        </div>
                      </Group>
                    </Paper>
                  </motion.div>
                )}
              </Stack>
            </Paper>
          </Grid.Col>

          {/* Game Canvas */}
          <Grid.Col span={{ base: 12, md: 9 }}>
            <Paper p="md" bg="dark.8" radius="md" h="640">
              <canvas
                ref={canvasRef}
                width={CANVAS_WIDTH}
                height={CANVAS_HEIGHT}
                style={{
                  width: '100%',
                  height: '100%',
                  background: 'linear-gradient(180deg, #0c1426 0%, #1a1f36 100%)',
                  borderRadius: '8px',
                  border: '2px solid #374151',
                  boxShadow: '0 8px 32px rgba(0, 0, 0, 0.4)'
                }}
              />
            </Paper>
          </Grid.Col>
        </Grid>

        {/* Multiplier Info */}
        <Paper p="md" bg="dark.7" radius="md">
          <Group justify="center" gap="md">
            <Group gap="xs">
              <Box w={12} h={12} bg="green.6" style={{ borderRadius: '50%' }} />
              <Text size="sm" c="dimmed">High Risk (100x+)</Text>
            </Group>
            <Group gap="xs">
              <Box w={12} h={12} bg="blue.6" style={{ borderRadius: '50%' }} />
              <Text size="sm" c="dimmed">Medium Risk (10x+)</Text>
            </Group>
            <Group gap="xs">
              <Box w={12} h={12} bg="gray.6" style={{ borderRadius: '50%' }} />
              <Text size="sm" c="dimmed">Low Risk (2x-9x)</Text>
            </Group>
          </Group>
        </Paper>
      </Stack>
    </Container>
  )
}