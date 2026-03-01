import { useState, useEffect } from 'react';
import { ref, onValue } from 'firebase/database';
import { db } from '../services/firebase';

export function useSensors() {
  const [sensors, setSensors] = useState({
    temperature: 0,
    humidity: 0,
    lightLevel: 0,
    studentsPresent: 0
  });
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const sensorsRef = ref(db, 'classroom/sensors');
    const unsubscribe = onValue(sensorsRef, (snapshot) => {
      const data = snapshot.val();
      if (data) {
        setSensors(data);
      }
      setLoading(false);
    });

    return () => unsubscribe();
  }, []);

  return { sensors, loading };
}
