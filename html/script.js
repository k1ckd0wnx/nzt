let isMenuOpen = false;
let vehicleCategories = [];
let allVehicles = [];

// DOM Elements
const container = document.getElementById('container');
const closeBtn = document.getElementById('closeBtn');
const searchInput = document.getElementById('searchInput');
const deleteVehicleBtn = document.getElementById('deleteVehicleBtn');
const categoriesContainer = document.getElementById('categoriesContainer');

// Initialize when DOM is loaded
document.addEventListener('DOMContentLoaded', function() {
    setupEventListeners();
});

// Event Listeners
function setupEventListeners() {
    // Close button
    closeBtn.addEventListener('click', closeMenu);
    
    // Delete vehicle button
    deleteVehicleBtn.addEventListener('click', function() {
        post('deleteVehicle', {});
    });
    
    // Search input
    searchInput.addEventListener('input', function() {
        filterVehicles(this.value);
    });
    
    // Keyboard events
    document.addEventListener('keydown', function(event) {
        if (event.key === 'Escape' && isMenuOpen) {
            closeMenu();
        }
    });
    
    // Prevent context menu
    document.addEventListener('contextmenu', function(event) {
        event.preventDefault();
    });
}

// Utility Functions
function post(event, data) {
    fetch(`https://vehiclespawner/${event}`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json; charset=UTF-8',
        },
        body: JSON.stringify(data)
    }).then(response => response.json()).then(data => {
        // Handle response if needed
    }).catch(error => {
        console.error('Error:', error);
    });
}

function createVehicleElement(vehicle, index) {
    const vehicleElement = document.createElement('div');
    vehicleElement.className = 'vehicle-item';
    vehicleElement.style.animationDelay = `${index * 0.05}s`;
    
    vehicleElement.innerHTML = `
        <div class="vehicle-name">${vehicle.name}</div>
        <div class="vehicle-model">${vehicle.model}</div>
    `;
    
    vehicleElement.addEventListener('click', function() {
        spawnVehicle(vehicle.model);
    });
    
    return vehicleElement;
}

function createCategoryElement(category, index) {
    const categoryElement = document.createElement('div');
    categoryElement.className = 'category';
    categoryElement.style.animationDelay = `${index * 0.1}s`;
    
    const categoryHeader = document.createElement('div');
    categoryHeader.className = 'category-header';
    categoryHeader.innerHTML = `
        <h3 class="category-title">${category.name}</h3>
        <span class="category-toggle">▼</span>
    `;
    
    const vehiclesGrid = document.createElement('div');
    vehiclesGrid.className = 'vehicles-grid';
    
    // Add vehicles to the grid
    category.vehicles.forEach((vehicle, vehicleIndex) => {
        const vehicleElement = createVehicleElement(vehicle, vehicleIndex);
        vehiclesGrid.appendChild(vehicleElement);
    });
    
    // Toggle functionality
    categoryHeader.addEventListener('click', function() {
        categoryElement.classList.toggle('collapsed');
        if (categoryElement.classList.contains('collapsed')) {
            vehiclesGrid.style.display = 'none';
        } else {
            vehiclesGrid.style.display = 'grid';
        }
    });
    
    categoryElement.appendChild(categoryHeader);
    categoryElement.appendChild(vehiclesGrid);
    
    return categoryElement;
}

function renderCategories() {
    categoriesContainer.innerHTML = '';
    
    vehicleCategories.forEach((category, index) => {
        const categoryElement = createCategoryElement(category, index);
        categoriesContainer.appendChild(categoryElement);
    });
}

function buildVehicleList() {
    allVehicles = [];
    vehicleCategories.forEach(category => {
        category.vehicles.forEach(vehicle => {
            allVehicles.push({
                ...vehicle,
                category: category.name
            });
        });
    });
}

function filterVehicles(searchTerm) {
    const filteredCategories = [];
    
    if (searchTerm.trim() === '') {
        // Show all categories
        renderCategories();
        return;
    }
    
    searchTerm = searchTerm.toLowerCase();
    
    vehicleCategories.forEach(category => {
        const filteredVehicles = category.vehicles.filter(vehicle => 
            vehicle.name.toLowerCase().includes(searchTerm) ||
            vehicle.model.toLowerCase().includes(searchTerm)
        );
        
        if (filteredVehicles.length > 0) {
            filteredCategories.push({
                name: category.name,
                vehicles: filteredVehicles
            });
        }
    });
    
    // Render filtered categories
    categoriesContainer.innerHTML = '';
    filteredCategories.forEach((category, index) => {
        const categoryElement = createCategoryElement(category, index);
        categoriesContainer.appendChild(categoryElement);
    });
    
    // If no results found
    if (filteredCategories.length === 0) {
        categoriesContainer.innerHTML = `
            <div style="text-align: center; padding: 40px; color: rgba(255, 255, 255, 0.6);">
                <h3>No vehicles found</h3>
                <p>Try a different search term</p>
            </div>
        `;
    }
}

function spawnVehicle(model) {
    post('spawnVehicle', { model: model });
    closeMenu();
}

function openMenu(categories) {
    vehicleCategories = categories || [];
    buildVehicleList();
    
    container.classList.remove('hidden');
    isMenuOpen = true;
    
    // Clear search
    searchInput.value = '';
    
    // Render categories
    renderCategories();
    
    // Focus on search input
    setTimeout(() => {
        searchInput.focus();
    }, 100);
}

function closeMenu() {
    container.classList.add('hidden');
    isMenuOpen = false;
    post('closeMenu', {});
}

// Message Handler from Lua
window.addEventListener('message', function(event) {
    const data = event.data;
    
    switch(data.type) {
        case 'openMenu':
            openMenu(data.categories);
            break;
            
        case 'closeMenu':
            closeMenu();
            break;
            
        default:
            break;
    }
});

// Additional Features

// Keyboard shortcuts for categories
document.addEventListener('keydown', function(event) {
    if (!isMenuOpen) return;
    
    // Number keys 1-9 to quickly access categories
    if (event.key >= '1' && event.key <= '9') {
        const categoryIndex = parseInt(event.key) - 1;
        if (categoryIndex < vehicleCategories.length) {
            const categoryElement = categoriesContainer.children[categoryIndex];
            if (categoryElement) {
                const header = categoryElement.querySelector('.category-header');
                header.click();
            }
        }
        event.preventDefault();
    }
    
    // Enter to spawn first vehicle in search results
    if (event.key === 'Enter') {
        const firstVehicle = categoriesContainer.querySelector('.vehicle-item');
        if (firstVehicle) {
            firstVehicle.click();
        }
        event.preventDefault();
    }
});

// Double-click to spawn vehicle quickly
function enableQuickSpawn() {
    let lastClickTime = 0;
    let lastClickedVehicle = null;
    
    document.addEventListener('click', function(event) {
        if (event.target.closest('.vehicle-item')) {
            const currentTime = new Date().getTime();
            const vehicleElement = event.target.closest('.vehicle-item');
            
            if (vehicleElement === lastClickedVehicle && currentTime - lastClickTime < 300) {
                // Double click detected
                const vehicleModel = vehicleElement.querySelector('.vehicle-model').textContent;
                spawnVehicle(vehicleModel);
            }
            
            lastClickedVehicle = vehicleElement;
            lastClickTime = currentTime;
        }
    });
}

// Enable quick spawn feature
enableQuickSpawn();

// Add loading animation
function showLoading() {
    categoriesContainer.innerHTML = `
        <div style="text-align: center; padding: 40px;">
            <div style="width: 40px; height: 40px; margin: 0 auto 20px; border: 3px solid rgba(255,255,255,0.3); border-top: 3px solid #4ecdc4; border-radius: 50%; animation: spin 1s linear infinite;"></div>
            <p style="color: rgba(255, 255, 255, 0.8);">Loading vehicles...</p>
        </div>
    `;
}

// Add CSS for loading animation
const style = document.createElement('style');
style.textContent = `
    @keyframes spin {
        0% { transform: rotate(0deg); }
        100% { transform: rotate(360deg); }
    }
`;
document.head.appendChild(style);

// Smooth scrolling for categories
function addSmoothScrolling() {
    const content = document.querySelector('.content');
    let isScrolling = false;
    
    content.addEventListener('wheel', function(event) {
        if (!isScrolling) {
            isScrolling = true;
            setTimeout(() => {
                isScrolling = false;
            }, 100);
            
            event.preventDefault();
            const scrollAmount = event.deltaY > 0 ? 100 : -100;
            content.scrollBy({
                top: scrollAmount,
                behavior: 'smooth'
            });
        }
    });
}

// Enable smooth scrolling
addSmoothScrolling();