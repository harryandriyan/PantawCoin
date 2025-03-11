document.addEventListener('DOMContentLoaded', function() {
    // Theme toggle functionality
    const themeToggle = document.getElementById('theme-toggle');
    const prefersDarkScheme = window.matchMedia('(prefers-color-scheme: dark)');
    
    // Check for saved theme preference or use the system preference
    const currentTheme = localStorage.getItem('theme') || 
                         (prefersDarkScheme.matches ? 'dark' : 'light');
    
    // Apply the current theme
    if (currentTheme === 'dark') {
        document.body.setAttribute('data-theme', 'dark');
        if (themeToggle) {
            themeToggle.innerHTML = '☀️';
            themeToggle.setAttribute('aria-label', 'Switch to light mode');
        }
    } else {
        document.body.removeAttribute('data-theme');
        if (themeToggle) {
            themeToggle.innerHTML = '🌙';
            themeToggle.setAttribute('aria-label', 'Switch to dark mode');
        }
    }
    
    // Theme toggle click handler
    if (themeToggle) {
        themeToggle.addEventListener('click', function() {
            let theme;
            
            // Toggle the theme
            if (document.body.getAttribute('data-theme') === 'dark') {
                document.body.removeAttribute('data-theme');
                theme = 'light';
                this.innerHTML = '🌙';
                this.setAttribute('aria-label', 'Switch to dark mode');
            } else {
                document.body.setAttribute('data-theme', 'dark');
                theme = 'dark';
                this.innerHTML = '☀️';
                this.setAttribute('aria-label', 'Switch to light mode');
            }
            
            // Save the preference
            localStorage.setItem('theme', theme);
        });
    }

    // Smooth scrolling for anchor links
    document.querySelectorAll('a[href^="#"]').forEach(anchor => {
        anchor.addEventListener('click', function(e) {
            e.preventDefault();
            
            const targetId = this.getAttribute('href');
            if (targetId === '#') return;
            
            const targetElement = document.querySelector(targetId);
            if (targetElement) {
                window.scrollTo({
                    top: targetElement.offsetTop - 70, // Adjust for header height
                    behavior: 'smooth'
                });
            }
        });
    });

    // Header scroll effect
    const header = document.querySelector('header');
    window.addEventListener('scroll', function() {
        if (window.scrollY > 50) {
            header.style.boxShadow = '0 4px 20px rgba(0, 0, 0, 0.15)';
            header.style.backdropFilter = 'blur(10px)';
            header.style.background = document.body.getAttribute('data-theme') === 'dark' 
                ? 'rgba(30, 30, 30, 0.8)' 
                : 'rgba(255, 255, 255, 0.8)';
        } else {
            header.style.boxShadow = 'var(--box-shadow)';
            header.style.backdropFilter = 'none';
            header.style.background = 'var(--card-background)';
        }
    });

    // Add animation to feature cards
    const featureCards = document.querySelectorAll('.feature-card');
    const observerOptions = {
        threshold: 0.1,
        rootMargin: '0px 0px -50px 0px'
    };

    const observer = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                entry.target.style.opacity = '1';
                entry.target.style.transform = 'translateY(0)';
                observer.unobserve(entry.target);
            }
        });
    }, observerOptions);

    featureCards.forEach((card, index) => {
        card.style.opacity = '0';
        card.style.transform = 'translateY(20px)';
        card.style.transition = `opacity 0.5s ease, transform 0.5s ease ${index * 0.1}s`;
        observer.observe(card);
    });
}); 