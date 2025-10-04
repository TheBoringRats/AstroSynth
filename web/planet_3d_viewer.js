// Interactive 3D Planet Viewer using Three.js
// Full 3D rendering with realistic surface textures based on planet data
// Supports zoom, rotation, pan, and detailed surface visualization

class Interactive3DPlanetViewer {
  constructor(containerId, planetData) {
    this.container = document.getElementById(containerId);
    if (!this.container) {
      console.error(`Container with id ${containerId} not found`);
      return;
    }

    this.planetData = planetData;
    this.width = this.container.clientWidth;
    this.height = this.container.clientHeight;

    // 3D Scene setup
    this.scene = null;
    this.camera = null;
    this.renderer = null;
    this.planet = null;
    this.atmosphere = null;
    this.clouds = null;
    this.rings = null;
    this.lights = [];

    // Interaction state
    this.isDragging = false;
    this.previousMousePosition = { x: 0, y: 0 };
    this.rotation = { x: 0, y: 0 };
    this.autoRotate = true;
    this.zoom = 1.0;

    // Animation
    this.animationId = null;

    // Initialize
    this.init();
    this.createPlanet();
    this.addLighting();
    this.setupControls();
    this.animate();

    // Handle window resize
    window.addEventListener("resize", () => this.onWindowResize());
  }

  init() {
    // Create scene
    this.scene = new THREE.Scene();
    this.scene.background = new THREE.Color(0x000510);

    // Create camera
    this.camera = new THREE.PerspectiveCamera(
      45,
      this.width / this.height,
      0.1,
      1000
    );
    this.camera.position.z = 5;

    // Create renderer
    this.renderer = new THREE.WebGLRenderer({ antialias: true, alpha: true });
    this.renderer.setSize(this.width, this.height);
    this.renderer.setPixelRatio(window.devicePixelRatio);
    this.container.appendChild(this.renderer.domElement);

    // Add stars
    this.addStarfield();
  }

  addStarfield() {
    const starGeometry = new THREE.BufferGeometry();
    const starCount = 1000;
    const positions = new Float32Array(starCount * 3);

    for (let i = 0; i < starCount * 3; i += 3) {
      positions[i] = (Math.random() - 0.5) * 200;
      positions[i + 1] = (Math.random() - 0.5) * 200;
      positions[i + 2] = (Math.random() - 0.5) * 200;
    }

    starGeometry.setAttribute(
      "position",
      new THREE.BufferAttribute(positions, 3)
    );

    const starMaterial = new THREE.PointsMaterial({
      color: 0xffffff,
      size: 0.1,
      transparent: true,
      opacity: 0.8,
    });

    const stars = new THREE.Points(starGeometry, starMaterial);
    this.scene.add(stars);
  }

  createPlanet() {
    const { temperature, mass, radius, biome, atmosphere } = this.planetData;
    const temp = temperature || 300;
    const planetRadius = Math.max(0.5, Math.min(2.5, (radius || 1) * 1.5));

    // Calculate colors based on planet data
    const colors = this.calculatePlanetColors();

    // Create main planet sphere with detailed geometry
    const geometry = new THREE.SphereGeometry(planetRadius, 128, 128);

    // Generate procedural surface texture based on planet type
    const texture = this.generateSurfaceTexture();

    const material = new THREE.MeshPhongMaterial({
      map: texture,
      bumpMap: this.generateBumpMap(),
      bumpScale: 0.05,
      emissive:
        temp > 800
          ? new THREE.Color(colors.emissive)
          : new THREE.Color(0x000000),
      emissiveIntensity: temp > 800 ? 0.3 : 0,
      shininess: biome === "Ocean World" ? 30 : 5,
      specular: biome === "Ocean World" ? 0x222222 : 0x111111,
    });

    this.planet = new THREE.Mesh(geometry, material);
    this.scene.add(this.planet);

    // Add atmosphere if applicable
    if (mass > 0.3 || biome === "Ocean World" || biome === "Gas Giant") {
      this.addAtmosphere(planetRadius, colors.atmosphere);
    }

    // Add clouds for suitable planets
    if (this.shouldHaveClouds()) {
      this.addClouds(planetRadius);
    }

    // Add rings for gas giants
    if (mass > 5 && Math.random() > 0.6) {
      this.addRings(planetRadius);
    }

    // Add special effects
    this.addSpecialEffects(planetRadius, colors);
  }

  calculatePlanetColors() {
    const { temperature, mass, density, biome } = this.planetData;
    const temp = temperature || 300;
    const uniqueSeed = this.hashCode(this.planetData.name) % 100;

    // Base colors by biome
    const biomeColors = {
      "Gas Giant": { base: 0x9370db, atmos: 0xa991e0, emissive: 0x000000 },
      "Ice Giant": { base: 0x87ceeb, atmos: 0x9fd8f0, emissive: 0x000000 },
      "Super Earth": { base: 0x8b7355, atmos: 0xa08970, emissive: 0x000000 },
      "Mini Neptune": { base: 0x4682b4, atmos: 0x5b94c5, emissive: 0x000000 },
      "Rocky Planet": { base: 0xa0826d, atmos: 0x000000, emissive: 0x000000 },
      "Ice World": { base: 0xe0f6ff, atmos: 0xedf8ff, emissive: 0x000000 },
      "Lava World": { base: 0xff4500, atmos: 0xff6600, emissive: 0xff4500 },
      "Ocean World": { base: 0x006994, atmos: 0x4d9fc7, emissive: 0x000000 },
      "Desert World": { base: 0xdaa520, atmos: 0xe5b840, emissive: 0x000000 },
      "Barren World": { base: 0x696969, atmos: 0x000000, emissive: 0x000000 },
    };

    // Default fallback colors
    const defaultColors = { base: 0x808080, atmos: 0x909090, emissive: 0x000000 };
    let colors = biomeColors[biome] || biomeColors["Barren World"] || defaultColors;

    // Ensure all color properties exist
    colors = {
      base: colors.base !== undefined ? colors.base : 0x808080,
      atmos: colors.atmos !== undefined ? colors.atmos : 0x909090,
      emissive: colors.emissive !== undefined ? colors.emissive : 0x000000
    };

    // Temperature modifications
    if (temp > 1500) {
      colors.base = 0xffffff;
      colors.emissive = 0xffaa00;
    } else if (temp > 800) {
      colors.base = this.adjustColor(colors.base, 1.2, 0.1);
      colors.emissive = 0xff6600;
    } else if (temp < 100) {
      colors.base = this.adjustColor(colors.base, 0.7, 0.2);
    }

    return colors;
  }

  generateSurfaceTexture() {
    const { temperature, biome, mass } = this.planetData;
    const temp = temperature || 300;
    const size = 1024;
    const canvas = document.createElement("canvas");
    canvas.width = size;
    canvas.height = size;
    const ctx = canvas.getContext("2d");

    const colors = this.calculatePlanetColors();
    const baseColor = "#" + colors.base.toString(16).padStart(6, "0");

    // Base gradient
    const gradient = ctx.createRadialGradient(
      size * 0.3,
      size * 0.3,
      size * 0.1,
      size * 0.5,
      size * 0.5,
      size * 0.7
    );
    gradient.addColorStop(0, this.lightenColor(baseColor, 30));
    gradient.addColorStop(0.5, baseColor);
    gradient.addColorStop(1, this.darkenColor(baseColor, 30));
    ctx.fillStyle = gradient;
    ctx.fillRect(0, 0, size, size);

    // Add biome-specific features
    if (
      biome === "Gas Giant" ||
      biome === "Ice Giant" ||
      biome === "Mini Neptune"
    ) {
      this.drawGasGiantBands(ctx, size, baseColor);
    } else if (biome === "Rocky Planet" || biome === "Barren World") {
      this.drawCraters(ctx, size);
    } else if (biome === "Lava World") {
      this.drawLavaVeins(ctx, size);
    } else if (biome === "Ice World") {
      this.drawIceCracks(ctx, size);
    } else if (biome === "Ocean World") {
      this.drawOceanPatterns(ctx, size, baseColor);
    } else if (biome === "Desert World") {
      this.drawDesertDunes(ctx, size, baseColor);
    }

    // Add surface noise for realism
    this.addSurfaceNoise(ctx, size);

    const texture = new THREE.CanvasTexture(canvas);
    texture.needsUpdate = true;
    return texture;
  }

  generateBumpMap() {
    const size = 512;
    const canvas = document.createElement("canvas");
    canvas.width = size;
    canvas.height = size;
    const ctx = canvas.getContext("2d");

    // Create noise-based bump map
    const imageData = ctx.createImageData(size, size);
    const seed = this.hashCode(this.planetData.name);

    for (let i = 0; i < imageData.data.length; i += 4) {
      const noise = this.perlinNoise(
        (i / 4) % size,
        Math.floor(i / 4 / size),
        seed
      );
      const value = Math.floor((noise + 1) * 127.5);
      imageData.data[i] = value;
      imageData.data[i + 1] = value;
      imageData.data[i + 2] = value;
      imageData.data[i + 3] = 255;
    }

    ctx.putImageData(imageData, 0, 0);

    const texture = new THREE.CanvasTexture(canvas);
    texture.needsUpdate = true;
    return texture;
  }

  drawGasGiantBands(ctx, size, baseColor) {
    const seed = this.hashCode(this.planetData.name);
    const numBands = 5 + (seed % 4);

    for (let i = 0; i < numBands; i++) {
      const y = (i / numBands) * size;
      const height = size / (numBands * 1.5);
      const offset = Math.sin(i * 0.5) * 20;

      const bandGradient = ctx.createLinearGradient(0, y, 0, y + height);
      const color1 =
        i % 2 === 0
          ? this.darkenColor(baseColor, 15)
          : this.lightenColor(baseColor, 10);
      const color2 = i % 2 === 0 ? baseColor : this.darkenColor(baseColor, 5);

      bandGradient.addColorStop(0, color1);
      bandGradient.addColorStop(0.5, color2);
      bandGradient.addColorStop(1, color1);

      ctx.fillStyle = bandGradient;
      ctx.globalAlpha = 0.6;

      // Draw wavy band
      ctx.beginPath();
      for (let x = 0; x <= size; x += 10) {
        const wave = Math.sin(x * 0.01 + i) * 10;
        const yPos = y + offset + wave;
        if (x === 0) {
          ctx.moveTo(x, yPos);
        } else {
          ctx.lineTo(x, yPos);
        }
      }
      ctx.lineTo(size, y + height);
      for (let x = size; x >= 0; x -= 10) {
        const wave = Math.sin(x * 0.01 + i) * 10;
        const yPos = y + height + offset + wave;
        ctx.lineTo(x, yPos);
      }
      ctx.closePath();
      ctx.fill();
      ctx.globalAlpha = 1.0;
    }

    // Add storm spot
    if (seed % 3 === 0) {
      const stormX = size * 0.6 + (seed % 100);
      const stormY = size * 0.4 + ((seed * 7) % 100);
      const stormGradient = ctx.createRadialGradient(
        stormX,
        stormY,
        10,
        stormX,
        stormY,
        40
      );
      stormGradient.addColorStop(0, "rgba(200, 100, 100, 0.6)");
      stormGradient.addColorStop(1, "rgba(200, 100, 100, 0)");
      ctx.fillStyle = stormGradient;
      ctx.beginPath();
      ctx.ellipse(stormX, stormY, 60, 40, 0, 0, Math.PI * 2);
      ctx.fill();
    }
  }

  drawCraters(ctx, size) {
    const seed = this.hashCode(this.planetData.name);
    const numCraters = 20 + (seed % 30);

    for (let i = 0; i < numCraters; i++) {
      const x = (seed + i * 137) % size;
      const y = (seed + i * 97) % size;
      const radius = 5 + ((seed + i) % 25);

      // Crater rim (dark)
      const rimGradient = ctx.createRadialGradient(x, y, 0, x, y, radius);
      rimGradient.addColorStop(0, "rgba(0, 0, 0, 0.6)");
      rimGradient.addColorStop(0.7, "rgba(0, 0, 0, 0.3)");
      rimGradient.addColorStop(1, "rgba(0, 0, 0, 0)");

      ctx.fillStyle = rimGradient;
      ctx.beginPath();
      ctx.arc(x, y, radius, 0, Math.PI * 2);
      ctx.fill();

      // Crater highlight
      const highlightGradient = ctx.createRadialGradient(
        x - radius * 0.3,
        y - radius * 0.3,
        0,
        x - radius * 0.3,
        y - radius * 0.3,
        radius * 0.5
      );
      highlightGradient.addColorStop(0, "rgba(255, 255, 255, 0.2)");
      highlightGradient.addColorStop(1, "rgba(255, 255, 255, 0)");

      ctx.fillStyle = highlightGradient;
      ctx.beginPath();
      ctx.arc(x - radius * 0.3, y - radius * 0.3, radius * 0.5, 0, Math.PI * 2);
      ctx.fill();
    }
  }

  drawLavaVeins(ctx, size) {
    const seed = this.hashCode(this.planetData.name);
    const numVeins = 15;

    ctx.strokeStyle = "rgba(255, 100, 0, 0.8)";
    ctx.lineWidth = 3;
    ctx.shadowBlur = 15;
    ctx.shadowColor = "rgba(255, 100, 0, 0.9)";

    for (let i = 0; i < numVeins; i++) {
      const startX = (seed + i * 73) % size;
      const startY = (seed + i * 97) % size;
      const angle = (((seed + i) % 360) * Math.PI) / 180;

      ctx.beginPath();
      ctx.moveTo(startX, startY);

      let x = startX;
      let y = startY;

      for (let j = 0; j < 10; j++) {
        x += Math.cos(angle + Math.sin(j) * 0.5) * 30;
        y += Math.sin(angle + Math.cos(j) * 0.5) * 30;
        ctx.lineTo(x, y);
      }

      ctx.stroke();
    }

    ctx.shadowBlur = 0;
  }

  drawIceCracks(ctx, size) {
    const seed = this.hashCode(this.planetData.name);
    const numCracks = 30;

    ctx.strokeStyle = "rgba(200, 230, 255, 0.4)";
    ctx.lineWidth = 2;

    for (let i = 0; i < numCracks; i++) {
      const startX = (seed + i * 137) % size;
      const startY = (seed + i * 97) % size;
      const angle = (((seed + i * 73) % 360) * Math.PI) / 180;
      const length = 30 + ((seed + i) % 60);

      ctx.beginPath();
      ctx.moveTo(startX, startY);

      for (let j = 0; j < 5; j++) {
        const x =
          startX +
          Math.cos(angle) * ((j * length) / 5) +
          (Math.random() - 0.5) * 10;
        const y =
          startY +
          Math.sin(angle) * ((j * length) / 5) +
          (Math.random() - 0.5) * 10;
        ctx.lineTo(x, y);
      }

      ctx.stroke();
    }
  }

  drawOceanPatterns(ctx, size, baseColor) {
    // Draw continents/landmasses
    const seed = this.hashCode(this.planetData.name);
    const numLandmasses = 3 + (seed % 4);

    ctx.fillStyle = this.lightenColor(baseColor, 40);

    for (let i = 0; i < numLandmasses; i++) {
      const x = ((seed + i * 137) % (size * 0.8)) + size * 0.1;
      const y = ((seed + i * 97) % (size * 0.8)) + size * 0.1;
      const radius = 50 + ((seed + i) % 100);

      ctx.globalAlpha = 0.7;
      ctx.beginPath();

      // Irregular landmass shape
      for (let angle = 0; angle < Math.PI * 2; angle += 0.5) {
        const r = radius * (0.7 + Math.random() * 0.6);
        const px = x + Math.cos(angle) * r;
        const py = y + Math.sin(angle) * r;
        if (angle === 0) {
          ctx.moveTo(px, py);
        } else {
          ctx.lineTo(px, py);
        }
      }

      ctx.closePath();
      ctx.fill();
      ctx.globalAlpha = 1.0;
    }

    // Add wave patterns
    ctx.strokeStyle = "rgba(255, 255, 255, 0.1)";
    ctx.lineWidth = 1;

    for (let i = 0; i < 20; i++) {
      ctx.beginPath();
      for (let x = 0; x < size; x += 10) {
        const y = (i / 20) * size + Math.sin(x * 0.02 + i) * 5;
        if (x === 0) {
          ctx.moveTo(x, y);
        } else {
          ctx.lineTo(x, y);
        }
      }
      ctx.stroke();
    }
  }

  drawDesertDunes(ctx, size, baseColor) {
    const seed = this.hashCode(this.planetData.name);
    const numDunes = 15;

    for (let i = 0; i < numDunes; i++) {
      const y = (i / numDunes) * size;
      const color =
        i % 2 === 0
          ? this.darkenColor(baseColor, 10)
          : this.lightenColor(baseColor, 10);

      ctx.fillStyle = color;
      ctx.globalAlpha = 0.3;

      ctx.beginPath();
      for (let x = 0; x <= size; x += 20) {
        const wave = Math.sin(x * 0.02 + i + seed) * 15;
        const yPos = y + wave;
        if (x === 0) {
          ctx.moveTo(x, yPos);
        } else {
          ctx.lineTo(x, yPos);
        }
      }
      ctx.lineTo(size, y + 30);
      ctx.lineTo(0, y + 30);
      ctx.closePath();
      ctx.fill();
      ctx.globalAlpha = 1.0;
    }
  }

  addSurfaceNoise(ctx, size) {
    const imageData = ctx.getImageData(0, 0, size, size);
    const data = imageData.data;

    for (let i = 0; i < data.length; i += 4) {
      const noise = (Math.random() - 0.5) * 20;
      data[i] += noise;
      data[i + 1] += noise;
      data[i + 2] += noise;
    }

    ctx.putImageData(imageData, 0, 0);
  }

  addAtmosphere(planetRadius, atmosphereColor) {
    const atmosphereGeometry = new THREE.SphereGeometry(
      planetRadius * 1.15,
      64,
      64
    );
    const atmosphereMaterial = new THREE.MeshPhongMaterial({
      color: atmosphereColor || 0x4d9fc7,
      transparent: true,
      opacity: 0.2,
      side: THREE.BackSide,
    });

    this.atmosphere = new THREE.Mesh(atmosphereGeometry, atmosphereMaterial);
    this.scene.add(this.atmosphere);
  }

  addClouds(planetRadius) {
    const cloudGeometry = new THREE.SphereGeometry(planetRadius * 1.05, 64, 64);
    const cloudTexture = this.generateCloudTexture();
    const cloudMaterial = new THREE.MeshPhongMaterial({
      map: cloudTexture,
      transparent: true,
      opacity: 0.4,
      depthWrite: false,
    });

    this.clouds = new THREE.Mesh(cloudGeometry, cloudMaterial);
    this.scene.add(this.clouds);
  }

  generateCloudTexture() {
    const size = 512;
    const canvas = document.createElement("canvas");
    canvas.width = size;
    canvas.height = size;
    const ctx = canvas.getContext("2d");

    ctx.fillStyle = "transparent";
    ctx.fillRect(0, 0, size, size);

    ctx.fillStyle = "rgba(255, 255, 255, 0.8)";

    const seed = this.hashCode(this.planetData.name);
    const numClouds = 50 + (seed % 50);

    for (let i = 0; i < numClouds; i++) {
      const x = (seed + i * 137) % size;
      const y = (seed + i * 97) % size;
      const radius = 20 + ((seed + i) % 40);

      const gradient = ctx.createRadialGradient(x, y, 0, x, y, radius);
      gradient.addColorStop(0, "rgba(255, 255, 255, 0.8)");
      gradient.addColorStop(1, "rgba(255, 255, 255, 0)");

      ctx.fillStyle = gradient;
      ctx.beginPath();
      ctx.arc(x, y, radius, 0, Math.PI * 2);
      ctx.fill();
    }

    const texture = new THREE.CanvasTexture(canvas);
    texture.needsUpdate = true;
    return texture;
  }

  addRings(planetRadius) {
    const innerRadius = planetRadius * 1.5;
    const outerRadius = planetRadius * 2.5;
    const ringGeometry = new THREE.RingGeometry(innerRadius, outerRadius, 128);

    const colors = this.calculatePlanetColors();
    const ringMaterial = new THREE.MeshBasicMaterial({
      color: colors.base || 0x808080,
      side: THREE.DoubleSide,
      transparent: true,
      opacity: 0.6,
    });

    this.rings = new THREE.Mesh(ringGeometry, ringMaterial);
    this.rings.rotation.x = Math.PI / 2.5;
    this.scene.add(this.rings);
  }

  addSpecialEffects(planetRadius, colors) {
    const { temperature } = this.planetData;
    const temp = temperature || 300;

    // Add glow for hot planets
    if (temp > 800) {
      const glowGeometry = new THREE.SphereGeometry(planetRadius * 1.2, 32, 32);
      const glowMaterial = new THREE.MeshBasicMaterial({
        color: colors.emissive || 0xff6600,
        transparent: true,
        opacity: 0.3,
        side: THREE.BackSide,
      });

      const glow = new THREE.Mesh(glowGeometry, glowMaterial);
      this.scene.add(glow);
    }
  }

  shouldHaveClouds() {
    const { biome, mass, temperature } = this.planetData;
    const temp = temperature || 300;

    return (
      (biome === "Ocean World" || biome === "Super Earth") &&
      mass > 0.5 &&
      temp > 200 &&
      temp < 400
    );
  }

  addLighting() {
    // Ambient light
    const ambientLight = new THREE.AmbientLight(0xffffff, 0.3);
    this.scene.add(ambientLight);

    // Main sun light
    const sunLight = new THREE.DirectionalLight(0xffffff, 1.2);
    sunLight.position.set(5, 3, 5);
    this.scene.add(sunLight);
    this.lights.push(sunLight);

    // Fill light
    const fillLight = new THREE.DirectionalLight(0x8888ff, 0.3);
    fillLight.position.set(-5, -2, -5);
    this.scene.add(fillLight);
    this.lights.push(fillLight);

    // Rim light
    const rimLight = new THREE.DirectionalLight(0xffffff, 0.5);
    rimLight.position.set(0, 5, -5);
    this.scene.add(rimLight);
    this.lights.push(rimLight);
  }

  setupControls() {
    const canvas = this.renderer.domElement;

    // Mouse wheel zoom
    canvas.addEventListener("wheel", (e) => {
      e.preventDefault();
      const delta = e.deltaY * 0.001;
      this.zoom = Math.max(0.5, Math.min(3.0, this.zoom + delta));
    });

    // Mouse drag to rotate
    canvas.addEventListener("mousedown", (e) => {
      this.isDragging = true;
      this.autoRotate = false;
      this.previousMousePosition = { x: e.clientX, y: e.clientY };
    });

    canvas.addEventListener("mousemove", (e) => {
      if (this.isDragging) {
        const deltaX = e.clientX - this.previousMousePosition.x;
        const deltaY = e.clientY - this.previousMousePosition.y;

        this.rotation.y += deltaX * 0.005;
        this.rotation.x += deltaY * 0.005;

        // Limit vertical rotation
        this.rotation.x = Math.max(
          -Math.PI / 2,
          Math.min(Math.PI / 2, this.rotation.x)
        );

        this.previousMousePosition = { x: e.clientX, y: e.clientY };
      }
    });

    canvas.addEventListener("mouseup", () => {
      this.isDragging = false;
    });

    canvas.addEventListener("mouseleave", () => {
      this.isDragging = false;
    });

    // Touch support
    canvas.addEventListener("touchstart", (e) => {
      if (e.touches.length === 1) {
        this.isDragging = true;
        this.autoRotate = false;
        this.previousMousePosition = {
          x: e.touches[0].clientX,
          y: e.touches[0].clientY,
        };
      }
    });

    canvas.addEventListener("touchmove", (e) => {
      if (this.isDragging && e.touches.length === 1) {
        const deltaX = e.touches[0].clientX - this.previousMousePosition.x;
        const deltaY = e.touches[0].clientY - this.previousMousePosition.y;

        this.rotation.y += deltaX * 0.005;
        this.rotation.x += deltaY * 0.005;

        this.rotation.x = Math.max(
          -Math.PI / 2,
          Math.min(Math.PI / 2, this.rotation.x)
        );

        this.previousMousePosition = {
          x: e.touches[0].clientX,
          y: e.touches[0].clientY,
        };
      }
    });

    canvas.addEventListener("touchend", () => {
      this.isDragging = false;
    });
  }

  animate() {
    this.animationId = requestAnimationFrame(() => this.animate());

    // Auto-rotation
    if (this.autoRotate && this.planet) {
      this.rotation.y += 0.002;
    }

    // Apply rotations
    if (this.planet) {
      this.planet.rotation.x = this.rotation.x;
      this.planet.rotation.y = this.rotation.y;
    }

    // Rotate atmosphere slightly faster
    if (this.atmosphere) {
      this.atmosphere.rotation.x = this.rotation.x;
      this.atmosphere.rotation.y = this.rotation.y + 0.1;
    }

    // Rotate clouds independently
    if (this.clouds) {
      this.clouds.rotation.x = this.rotation.x;
      this.clouds.rotation.y = this.rotation.y + 0.05;
    }

    // Update camera zoom
    this.camera.position.z = 5 / this.zoom;

    this.renderer.render(this.scene, this.camera);
  }

  onWindowResize() {
    this.width = this.container.clientWidth;
    this.height = this.container.clientHeight;

    this.camera.aspect = this.width / this.height;
    this.camera.updateProjectionMatrix();

    this.renderer.setSize(this.width, this.height);
  }

  destroy() {
    if (this.animationId) {
      cancelAnimationFrame(this.animationId);
    }

    if (this.renderer) {
      this.renderer.dispose();
      if (this.container && this.renderer.domElement) {
        this.container.removeChild(this.renderer.domElement);
      }
    }

    // Clean up geometries and materials
    if (this.scene) {
      this.scene.traverse((object) => {
        if (object.geometry) {
          object.geometry.dispose();
        }
        if (object.material) {
          if (Array.isArray(object.material)) {
            object.material.forEach((material) => material.dispose());
          } else {
            object.material.dispose();
          }
        }
      });
    }
  }

  // Helper functions
  hashCode(str) {
    let hash = 0;
    for (let i = 0; i < str.length; i++) {
      const char = str.charCodeAt(i);
      hash = (hash << 5) - hash + char;
      hash = hash & hash;
    }
    return Math.abs(hash);
  }

  perlinNoise(x, y, seed) {
    // Simple pseudo-random noise
    const n = Math.sin(x * 12.9898 + y * 78.233 + seed) * 43758.5453;
    return (n - Math.floor(n)) * 2 - 1;
  }

  adjustColor(color, brightness, saturation) {
    // Simple color adjustment (placeholder)
    return color;
  }

  lightenColor(hex, percent) {
    const num = parseInt(hex.replace("#", ""), 16);
    const r = Math.min(255, ((num >> 16) & 255) + percent);
    const g = Math.min(255, ((num >> 8) & 255) + percent);
    const b = Math.min(255, (num & 255) + percent);
    return `rgb(${r}, ${g}, ${b})`;
  }

  darkenColor(hex, percent) {
    const num = parseInt(hex.replace("#", ""), 16);
    const r = Math.max(0, ((num >> 16) & 255) - percent);
    const g = Math.max(0, ((num >> 8) & 255) - percent);
    const b = Math.max(0, (num & 255) - percent);
    return `rgb(${r}, ${g}, ${b})`;
  }
}

// Global registry
window.planet3DViewers = window.planet3DViewers || {};

// Function to create 3D viewer
window.create3DPlanetViewer = function (containerId, planetData) {
  if (window.planet3DViewers[containerId]) {
    window.planet3DViewers[containerId].destroy();
  }

  window.planet3DViewers[containerId] = new Interactive3DPlanetViewer(
    containerId,
    planetData
  );
  return window.planet3DViewers[containerId];
};

// Function to destroy 3D viewer
window.destroy3DPlanetViewer = function (containerId) {
  if (window.planet3DViewers[containerId]) {
    window.planet3DViewers[containerId].destroy();
    delete window.planet3DViewers[containerId];
  }
};
