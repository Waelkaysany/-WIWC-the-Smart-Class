/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        background: '#0a0a14', // Deep space dark
        surface: '#12121f',
        primary: '#6C63FF', // Neon Purple
        secondary: '#00D4FF', // Cyan
        accent: '#FF007A', // Pink
        success: '#00E676',
        warning: '#FFEA00',
        error: '#FF1744',
      },
      fontFamily: {
        sans: ['Inter', 'sans-serif'],
      },
      animation: {
        'pulse-slow': 'pulse 3s cubic-bezier(0.4, 0, 0.6, 1) infinite',
        'spin-slow': 'spin 3s linear infinite',
      },
    },
  },
  plugins: [],
}
