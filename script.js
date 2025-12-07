// Mobile Navigation Toggle
const navToggle = document.getElementById('navToggle');
const navMenu = document.getElementById('navMenu');

navToggle.addEventListener('click', () => {
    navMenu.classList.toggle('active');
    navToggle.classList.toggle('active');
});

// Close mobile menu when clicking on a link
const navLinks = document.querySelectorAll('.nav-menu a');
navLinks.forEach(link => {
    link.addEventListener('click', () => {
        navMenu.classList.remove('active');
        navToggle.classList.remove('active');
    });
});

// Smooth Scrolling
document.querySelectorAll('a[href^="#"]').forEach(anchor => {
    anchor.addEventListener('click', function (e) {
        e.preventDefault();
        const target = document.querySelector(this.getAttribute('href'));
        if (target) {
            const offsetTop = target.offsetTop - 70;
            window.scrollTo({
                top: offsetTop,
                behavior: 'smooth'
            });
        }
    });
});

// Navbar background change on scroll
const navbar = document.querySelector('.navbar');
window.addEventListener('scroll', () => {
    if (window.scrollY > 50) {
        navbar.style.boxShadow = '0 4px 20px rgba(0, 0, 0, 0.15)';
    } else {
        navbar.style.boxShadow = '0 2px 10px rgba(0, 0, 0, 0.1)';
    }
});

// Intersection Observer for scroll animations
const observerOptions = {
    threshold: 0.1,
    rootMargin: '0px 0px -100px 0px'
};

const observer = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
        if (entry.isIntersecting) {
            entry.target.style.opacity = '1';
            entry.target.style.transform = 'translateY(0)';
        }
    });
}, observerOptions);

// Observe feature cards
const featureCards = document.querySelectorAll('.feature-card');
featureCards.forEach((card, index) => {
    card.style.opacity = '0';
    card.style.transform = 'translateY(30px)';
    card.style.transition = `all 0.6s ease ${index * 0.1}s`;
    observer.observe(card);
});

// Observe about section
const aboutText = document.querySelector('.about-text');
const aboutImage = document.querySelector('.about-image');

if (aboutText) {
    aboutText.style.opacity = '0';
    aboutText.style.transform = 'translateX(-30px)';
    aboutText.style.transition = 'all 0.8s ease';
    observer.observe(aboutText);
}

if (aboutImage) {
    aboutImage.style.opacity = '0';
    aboutImage.style.transform = 'translateX(30px)';
    aboutImage.style.transition = 'all 0.8s ease';
    observer.observe(aboutImage);
}

// Stats counter animation
const stats = document.querySelectorAll('.stat-number');
const statsSection = document.querySelector('.stats');

const animateStats = () => {
    stats.forEach(stat => {
        const target = stat.textContent;
        const isPercentage = target.includes('%');
        const isPlus = target.includes('+');
        const numericValue = parseInt(target.replace(/\D/g, ''));

        let count = 0;
        const increment = numericValue / 50;
        const timer = setInterval(() => {
            count += increment;
            if (count >= numericValue) {
                stat.textContent = target;
                clearInterval(timer);
            } else {
                if (isPercentage) {
                    stat.textContent = Math.floor(count) + '%';
                } else if (isPlus) {
                    stat.textContent = Math.floor(count) + 'k+';
                } else {
                    stat.textContent = Math.floor(count) + '+';
                }
            }
        }, 30);
    });
};

let statsAnimated = false;
const statsObserver = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
        if (entry.isIntersecting && !statsAnimated) {
            animateStats();
            statsAnimated = true;
        }
    });
}, { threshold: 0.5 });

if (statsSection) {
    statsObserver.observe(statsSection);
}

// Form submission handling
const ctaForm = document.getElementById('ctaForm');
ctaForm.addEventListener('submit', (e) => {
    e.preventDefault();
    const email = ctaForm.querySelector('input[type="email"]').value;

    // Show success message
    const button = ctaForm.querySelector('button');
    const originalText = button.textContent;
    button.textContent = 'Success!';
    button.style.background = '#48bb78';

    // Reset after 3 seconds
    setTimeout(() => {
        button.textContent = originalText;
        button.style.background = '';
        ctaForm.reset();
    }, 3000);

    // In a real application, you would send this data to a server
    console.log('Email submitted:', email);
});

// Add parallax effect to hero shapes
window.addEventListener('scroll', () => {
    const scrolled = window.pageYOffset;
    const shapes = document.querySelectorAll('.shape');

    shapes.forEach((shape, index) => {
        const speed = (index + 1) * 0.5;
        shape.style.transform = `translateY(${scrolled * speed}px)`;
    });
});

// Add cursor effect for feature cards
featureCards.forEach(card => {
    card.addEventListener('mouseenter', function(e) {
        this.style.transform = 'translateY(-10px) scale(1.02)';
    });

    card.addEventListener('mouseleave', function(e) {
        this.style.transform = 'translateY(-10px) scale(1)';
    });

    card.addEventListener('mousemove', function(e) {
        const rect = this.getBoundingClientRect();
        const x = e.clientX - rect.left;
        const y = e.clientY - rect.top;

        const centerX = rect.width / 2;
        const centerY = rect.height / 2;

        const rotateX = (y - centerY) / 20;
        const rotateY = (centerX - x) / 20;

        this.style.transform = `translateY(-10px) perspective(1000px) rotateX(${rotateX}deg) rotateY(${rotateY}deg)`;
    });
});

// Add active state to navigation based on scroll position
const sections = document.querySelectorAll('section[id]');

window.addEventListener('scroll', () => {
    let current = '';
    sections.forEach(section => {
        const sectionTop = section.offsetTop;
        const sectionHeight = section.clientHeight;
        if (window.pageYOffset >= sectionTop - 100) {
            current = section.getAttribute('id');
        }
    });

    navLinks.forEach(link => {
        link.classList.remove('active');
        if (link.getAttribute('href') === `#${current}`) {
            link.classList.add('active');
        }
    });
});

// Console message
console.log('%cWelcome to InnovateTech! 🚀', 'color: #667eea; font-size: 20px; font-weight: bold;');
console.log('%cBuilding the future of business technology', 'color: #764ba2; font-size: 14px;');
