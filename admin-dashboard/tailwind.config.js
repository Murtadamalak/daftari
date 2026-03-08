/** @type {import('tailwindcss').Config} */
export default {
    content: [
        "./index.html",
        "./src/**/*.{js,ts,jsx,tsx}",
    ],
    theme: {
        extend: {
            colors: {
                background: '#0F172A',
                surface: '#1E293B',
                primary: '#6366F1',
                success: '#22C55E',
                danger: '#EF4444',
                warning: '#F59E0B'
            },
            fontFamily: {
                tajawal: ['Tajawal', 'sans-serif'],
            }
        },
    },
    plugins: [],
}
