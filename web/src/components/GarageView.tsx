import { useState, useEffect } from 'react'
import {
  Modal,
  Text,
  Button,
  Group,
  Stack,
  Card,
  Badge,
  ScrollArea,
  TextInput,
  Select,
  Grid,
  ActionIcon,
  Tooltip,
  Alert,
  Progress,
  Center,
  Loader,
} from '@mantine/core'
import {
  IconCar,
  IconGasStation,
  IconHeart,
  IconHeartFilled,
  IconSettings,
  IconTransfer,
  IconTrash,
  IconX,
  IconSearch,
  IconFilter,
  IconStar,
  IconStarFilled,
} from '@tabler/icons-react'
import { notifications } from '@mantine/notifications'
import { modals } from '@mantine/modals'
import { fetchNui } from '../utils/fetchNui'

interface Vehicle {
  plate: string
  vehicle: string
  nickname?: string
  fuel: number
  engine: number
  body: number
  favorite: boolean
  state: string
  garage: string
}

interface Garage {
  name: string
  label: string
  type: string
  max_vehicles: number
  vehicle_types: string[]
}

interface GarageViewProps {
  garage: Garage
  onClose: () => void
}

const GarageView = ({ garage, onClose }: GarageViewProps) => {
  const [vehicles, setVehicles] = useState<Vehicle[]>([])
  const [loading, setLoading] = useState(true)
  const [searchTerm, setSearchTerm] = useState('')
  const [filterType, setFilterType] = useState<string>('all')
  const [sortBy, setSortBy] = useState<string>('plate')

  // Load vehicles
  useEffect(() => {
    loadVehicles()
  }, [garage.name])

  const loadVehicles = async () => {
    setLoading(true)
    try {
      const vehicleData = await fetchNui('getVehicles', { garage: garage.name }, [
        {
          plate: 'ABC123',
          vehicle: 'adder',
          nickname: 'My Supercar',
          fuel: 85,
          engine: 950,
          body: 980,
          favorite: true,
          state: 'garaged',
          garage: garage.name,
        },
        {
          plate: 'XYZ789',
          vehicle: 'sultan',
          nickname: null,
          fuel: 62,
          engine: 1000,
          body: 1000,
          favorite: false,
          state: 'garaged',
          garage: garage.name,
        },
      ])
      setVehicles(vehicleData)
    } catch (error) {
      notifications.show({
        title: 'Error',
        message: 'Failed to load vehicles',
        color: 'red',
      })
    } finally {
      setLoading(false)
    }
  }

  // Filter and sort vehicles
  const filteredVehicles = vehicles
    .filter((vehicle) => {
      const matchesSearch = 
        vehicle.plate.toLowerCase().includes(searchTerm.toLowerCase()) ||
        vehicle.vehicle.toLowerCase().includes(searchTerm.toLowerCase()) ||
        (vehicle.nickname && vehicle.nickname.toLowerCase().includes(searchTerm.toLowerCase()))
      
      const matchesFilter = 
        filterType === 'all' ||
        (filterType === 'favorites' && vehicle.favorite) ||
        (filterType === 'damaged' && (vehicle.engine < 800 || vehicle.body < 800))
      
      return matchesSearch && matchesFilter
    })
    .sort((a, b) => {
      switch (sortBy) {
        case 'plate':
          return a.plate.localeCompare(b.plate)
        case 'vehicle':
          return a.vehicle.localeCompare(b.vehicle)
        case 'fuel':
          return b.fuel - a.fuel
        case 'damage':
          return (a.engine + a.body) - (b.engine + b.body)
        default:
          return 0
      }
    })

  // Spawn vehicle
  const handleSpawnVehicle = async (plate: string) => {
    try {
      await fetchNui('spawnVehicle', { plate, garage: garage.name })
      notifications.show({
        title: 'Success',
        message: 'Vehicle spawned successfully',
        color: 'green',
      })
      onClose()
    } catch (error) {
      notifications.show({
        title: 'Error',
        message: 'Failed to spawn vehicle',
        color: 'red',
      })
    }
  }

  // Toggle favorite
  const handleToggleFavorite = async (plate: string) => {
    try {
      await fetchNui('toggleFavorite', { plate })
      setVehicles(prev => 
        prev.map(v => 
          v.plate === plate ? { ...v, favorite: !v.favorite } : v
        )
      )
      notifications.show({
        title: 'Success',
        message: 'Vehicle favorite status updated',
        color: 'green',
      })
    } catch (error) {
      notifications.show({
        title: 'Error',
        message: 'Failed to update favorite status',
        color: 'red',
      })
    }
  }

  // Rename vehicle
  const handleRenameVehicle = (plate: string, currentName?: string) => {
    modals.openConfirmModal({
      title: 'Rename Vehicle',
      children: (
        <TextInput
          label="Vehicle Nickname"
          placeholder="Enter new nickname"
          defaultValue={currentName || ''}
          data-autofocus
        />
      ),
      labels: { confirm: 'Rename', cancel: 'Cancel' },
      onConfirm: async () => {
        const input = document.querySelector('input[data-autofocus]') as HTMLInputElement
        const newName = input?.value
        
        if (newName) {
          try {
            await fetchNui('renameVehicle', { plate, newName })
            setVehicles(prev => 
              prev.map(v => 
                v.plate === plate ? { ...v, nickname: newName } : v
              )
            )
            notifications.show({
              title: 'Success',
              message: 'Vehicle renamed successfully',
              color: 'green',
            })
          } catch (error) {
            notifications.show({
              title: 'Error',
              message: 'Failed to rename vehicle',
              color: 'red',
            })
          }
        }
      },
    })
  }

  // Transfer vehicle
  const handleTransferVehicle = (plate: string) => {
    modals.openConfirmModal({
      title: 'Transfer Vehicle',
      children: (
        <Select
          label="Target Garage"
          placeholder="Select garage"
          data={[
            { value: 'legion_garage', label: 'Legion Square Garage' },
            { value: 'airport_garage', label: 'Airport Garage' },
            { value: 'boat_marina', label: 'Marina Boat Garage' },
          ]}
          data-autofocus
        />
      ),
      labels: { confirm: 'Transfer', cancel: 'Cancel' },
      onConfirm: async () => {
        const select = document.querySelector('select[data-autofocus]') as HTMLSelectElement
        const targetGarage = select?.value
        
        if (targetGarage) {
          try {
            await fetchNui('transferVehicle', { plate, targetGarage })
            setVehicles(prev => prev.filter(v => v.plate !== plate))
            notifications.show({
              title: 'Success',
              message: 'Vehicle transferred successfully',
              color: 'green',
            })
          } catch (error) {
            notifications.show({
              title: 'Error',
              message: 'Failed to transfer vehicle',
              color: 'red',
            })
          }
        }
      },
    })
  }

  const getHealthColor = (health: number) => {
    if (health >= 900) return 'green'
    if (health >= 700) return 'yellow'
    if (health >= 500) return 'orange'
    return 'red'
  }

  const getVehicleDisplayName = (model: string) => {
    // Convert model name to display name (basic implementation)
    return model.charAt(0).toUpperCase() + model.slice(1).replace(/[0-9]/g, ' $&').trim()
  }

  return (
    <Modal
      opened={true}
      onClose={onClose}
      title={
        <Group>
          <IconCar size={24} color="var(--mantine-color-blue-6)" />
          <Text size="xl" fw={600} c="blue.6">
            {garage.label}
          </Text>
          <Badge color="blue" variant="light">
            {garage.type}
          </Badge>
        </Group>
      }
      size="xl"
      styles={{
        content: {
          backgroundColor: 'var(--mantine-color-gray-0)',
        },
        header: {
          backgroundColor: 'var(--mantine-color-blue-0)',
          borderBottom: '2px solid var(--mantine-color-blue-6)',
        },
      }}
    >
      <Stack gap="md">
        {/* Search and filters */}
        <Grid>
          <Grid.Col span={6}>
            <TextInput
              placeholder="Search vehicles..."
              leftSection={<IconSearch size={16} />}
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
            />
          </Grid.Col>
          <Grid.Col span={3}>
            <Select
              placeholder="Filter"
              leftSection={<IconFilter size={16} />}
              value={filterType}
              onChange={(value) => setFilterType(value || 'all')}
              data={[
                { value: 'all', label: 'All Vehicles' },
                { value: 'favorites', label: 'Favorites' },
                { value: 'damaged', label: 'Damaged' },
              ]}
            />
          </Grid.Col>
          <Grid.Col span={3}>
            <Select
              placeholder="Sort by"
              value={sortBy}
              onChange={(value) => setSortBy(value || 'plate')}
              data={[
                { value: 'plate', label: 'Plate' },
                { value: 'vehicle', label: 'Model' },
                { value: 'fuel', label: 'Fuel' },
                { value: 'damage', label: 'Condition' },
              ]}
            />
          </Grid.Col>
        </Grid>

        {/* Vehicle count */}
        <Group justify="space-between">
          <Text size="sm" c="dimmed">
            {filteredVehicles.length} of {vehicles.length} vehicles
          </Text>
          <Progress
            value={(vehicles.length / garage.max_vehicles) * 100}
            size="sm"
            w={150}
            color="blue"
          />
        </Group>

        {/* Vehicles list */}
        <ScrollArea h={400}>
          {loading ? (
            <Center h={400}>
              <Loader color="blue" />
            </Center>
          ) : filteredVehicles.length === 0 ? (
            <Center h={400}>
              <Alert color="blue" title="No vehicles found">
                {vehicles.length === 0 
                  ? 'You have no vehicles in this garage.'
                  : 'No vehicles match your search criteria.'
                }
              </Alert>
            </Center>
          ) : (
            <Stack gap="xs">
              {filteredVehicles.map((vehicle) => (
                <Card
                  key={vehicle.plate}
                  padding="md"
                  withBorder
                  style={{
                    borderColor: vehicle.favorite 
                      ? 'var(--mantine-color-blue-6)' 
                      : 'var(--mantine-color-gray-3)',
                    borderWidth: vehicle.favorite ? 2 : 1,
                  }}
                >
                  <Group justify="space-between" align="flex-start">
                    <Stack gap="xs" style={{ flex: 1 }}>
                      <Group>
                        <Text fw={600} size="lg" c="blue.7">
                          {vehicle.nickname || getVehicleDisplayName(vehicle.vehicle)}
                        </Text>
                        <Badge color="gray" variant="light">
                          {vehicle.plate}
                        </Badge>
                        {vehicle.favorite && (
                          <IconStarFilled size={16} color="var(--mantine-color-yellow-6)" />
                        )}
                      </Group>
                      
                      <Group gap="lg">
                        <Group gap="xs">
                          <IconGasStation size={16} />
                          <Text size="sm">Fuel: {vehicle.fuel}%</Text>
                          <Progress value={vehicle.fuel} size="sm" w={60} color="blue" />
                        </Group>
                        
                        <Group gap="xs">
                          <Text size="sm">Engine: {Math.round(vehicle.engine / 10)}%</Text>
                          <Progress 
                            value={vehicle.engine / 10} 
                            size="sm" 
                            w={60} 
                            color={getHealthColor(vehicle.engine)} 
                          />
                        </Group>
                        
                        <Group gap="xs">
                          <Text size="sm">Body: {Math.round(vehicle.body / 10)}%</Text>
                          <Progress 
                            value={vehicle.body / 10} 
                            size="sm" 
                            w={60} 
                            color={getHealthColor(vehicle.body)} 
                          />
                        </Group>
                      </Group>
                    </Stack>

                    <Group gap="xs">
                      <Tooltip label={vehicle.favorite ? 'Remove from favorites' : 'Add to favorites'}>
                        <ActionIcon
                          variant="light"
                          color={vehicle.favorite ? 'yellow' : 'gray'}
                          onClick={() => handleToggleFavorite(vehicle.plate)}
                        >
                          {vehicle.favorite ? <IconStarFilled size={16} /> : <IconStar size={16} />}
                        </ActionIcon>
                      </Tooltip>

                      <Tooltip label="Rename vehicle">
                        <ActionIcon
                          variant="light"
                          color="blue"
                          onClick={() => handleRenameVehicle(vehicle.plate, vehicle.nickname)}
                        >
                          <IconSettings size={16} />
                        </ActionIcon>
                      </Tooltip>

                      <Tooltip label="Transfer vehicle">
                        <ActionIcon
                          variant="light"
                          color="orange"
                          onClick={() => handleTransferVehicle(vehicle.plate)}
                        >
                          <IconTransfer size={16} />
                        </ActionIcon>
                      </Tooltip>

                      <Button
                        color="blue"
                        size="sm"
                        onClick={() => handleSpawnVehicle(vehicle.plate)}
                      >
                        Spawn
                      </Button>
                    </Group>
                  </Group>
                </Card>
              ))}
            </Stack>
          )}
        </ScrollArea>

        {/* Footer */}
        <Group justify="space-between">
          <Text size="xs" c="dimmed">
            Garage Type: {garage.type} • Max Vehicles: {garage.max_vehicles}
          </Text>
          <Button variant="light" color="gray" onClick={onClose}>
            Close
          </Button>
        </Group>
      </Stack>
    </Modal>
  )
}

export default GarageView