import { initializeApp } from 'firebase/app';
import { getAuth } from 'firebase/auth';
import { getDatabase } from 'firebase/database';

const firebaseConfig = {
  apiKey: "AIzaSyCiXjjBLZnMCyKhzYQUv8Tz2fYSHbpwepo",
  authDomain: "wiwc-smartclass.firebaseapp.com",
  databaseURL: "https://wiwc-smartclass-default-rtdb.firebaseio.com",
  projectId: "wiwc-smartclass",
  storageBucket: "wiwc-smartclass.firebasestorage.app",
  messagingSenderId: "1090749757095",
  appId: "1:1090749757095:web:a1195838c5af9f11dacd82",
  measurementId: "G-5BCGHSBMHV"
};

const app = initializeApp(firebaseConfig);
export const auth = getAuth(app);
export const db = getDatabase(app);
