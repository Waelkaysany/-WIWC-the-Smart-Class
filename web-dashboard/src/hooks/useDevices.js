import { useState, useEffect } from 'react';
import { ref, onValue, update } from 'firebase/database';
import { db } from '../services/firebase';

export function useDevices() {
  const [devices, setDevices] = useState({});
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const devicesRef = ref(db, 'classroom/devices');
    const unsubscribe = onValue(devicesRef, (snapshot) => {
      const data = snapshot.val();
      if (data) {
        setDevices(data);
      }
      setLoading(false);
    });

    return () => unsubscribe();
  }, []);

  const toggleDevice = (deviceId, currentState) => {
    update(ref(db, `classroom/devices/${deviceId}`), {
      isOn: !currentState
    });
  };

  return { devices, loading, toggleDevice };
}
