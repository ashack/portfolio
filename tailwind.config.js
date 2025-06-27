const defaultTheme = require('tailwindcss/defaultTheme')

module.exports = {
  content: [
    './public/*.html',
    './app/helpers/**/*.rb',
    './app/javascript/**/*.js',
    './app/views/**/*.{erb,haml,html,slim}'
  ],
  safelist: [
    // Form focus states
    'focus:ring-indigo-500',
    'focus:ring-purple-500',
    'focus:ring-blue-500',
    'focus:border-indigo-500',
    'focus:border-purple-500',
    'focus:border-blue-500',
    // Checkbox colors
    'text-indigo-600',
    'text-purple-600',
    'text-blue-600',
    // File upload button colors
    'file:bg-indigo-50',
    'file:bg-purple-50',
    'file:bg-blue-50',
    'file:text-indigo-700',
    'file:text-purple-700',
    'file:text-blue-700',
    'hover:file:bg-indigo-100',
    'hover:file:bg-purple-100',
    'hover:file:bg-blue-100',
    // Navigation active states
    'border-indigo-500',
    'border-blue-500',
    'border-purple-500',
    // Animation classes
    'animate-pulse',
    'scale-95',
    'scale-100',
    'opacity-0',
    'opacity-100',
    // Gradient classes
    'bg-gradient-to-r',
    'from-indigo-600',
    'to-indigo-700',
    'from-indigo-500',
    'to-indigo-600'
  ],
  theme: {
    extend: {
      fontFamily: {
        sans: ['Inter var', ...defaultTheme.fontFamily.sans],
      },
    },
  },
  plugins: [
    require('@tailwindcss/forms'),
    require('@tailwindcss/typography'),
    require('@tailwindcss/container-queries'),
  ]
}