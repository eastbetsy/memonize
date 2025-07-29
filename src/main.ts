import { createApp } from 'vue'
import { createPinia } from 'pinia'
import Toast, { type PluginOptions } from 'vue-toastification'
import App from './App.vue'
import router from './router'
import 'vue-toastification/dist/index.css'
import './index.css'

// Create pinia store
const pinia = createPinia()

// Toast configuration options
const toastOptions: PluginOptions = {
  position: 'top-right',
  timeout: 3000,
  closeOnClick: true,
  pauseOnFocusLoss: true,
  pauseOnHover: true,
  draggable: true,
  draggablePercent: 0.6,
  showCloseButtonOnHover: false,
  hideProgressBar: false,
  closeButton: false,
  icon: true,
  rtl: false,
  toastClassName: 'cosmic-toast',
  bodyClassName: [],
  containerClassName: []
}

// Create and mount the app
createApp(App)
  .use(pinia)
  .use(router)
  .use(Toast, toastOptions)
  .mount('#app')