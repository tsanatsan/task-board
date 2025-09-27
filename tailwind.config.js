/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        priority: {
          low: '#10B981',
          medium: '#F59E0B',
          high: '#EF4444'
        }
      },
      animation: {
        'float': 'float 6s ease-in-out infinite',
        'dock-appear': 'dock-appear 0.3s ease-out',
      },
      keyframes: {
        float: {
          '0%, 100%': { transform: 'translateY(0px)' },
          '50%': { transform: 'translateY(-10px)' },
        },
        'dock-appear': {
          '0%': { 
            opacity: '0',
            transform: 'translateY(100%)'
          },
          '100%': { 
            opacity: '1',
            transform: 'translateY(0)'
          },
        }
      }
    },
  },
  plugins: [],
}