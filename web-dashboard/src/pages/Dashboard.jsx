import { useSensors } from '../hooks/useSensors';
import { useDevices } from '../hooks/useDevices';
import Layout from '../components/layout/Layout';
import StatsCard from '../components/dashboard/StatsCard';
import SensorChart from '../components/dashboard/SensorChart';
import { Thermometer, Droplets, Sun, Users, Lightbulb, Fan, Lock, Monitor, Speaker, Projector, Grid } from 'lucide-react';
import { motion } from 'framer-motion';

export default function Dashboard() {
  const { sensors } = useSensors();
  const { devices, toggleDevice } = useDevices();

  // Helper to get icon for device
  const getDeviceIcon = (id) => {
    switch (id) {
      case 'lights': return Lightbulb;
      case 'ac': return Fan; // No AC icon in lucide basically, Fan is close
      case 'door': return Lock;
      case 'projector': return Projector; // Or Monitor
      case 'board': return Monitor;
      case 'speakers': return Speaker;
      default: return Grid;
    }
  };

  const containerStats = {
    hidden: { opacity: 0 },
    show: {
      opacity: 1,
      transition: { staggerChildren: 0.1 }
    }
  };

  if (!sensors || !devices) {
    return (
      <Layout>
        <div className="flex items-center justify-center h-[calc(100vh-100px)]">
          <div className="animate-spin rounded-full h-12 w-12 border-t-2 border-b-2 border-primary"></div>
        </div>
      </Layout>
    );
  }

  return (
    <Layout>
      <div className="mb-8 flex justify-between items-end">
        <div>
          <h1 className="text-3xl font-bold mb-2">Dashboard Overview</h1>
          <p className="text-gray-400">Real-time classroom monitoring • Room 304</p>
        </div>
        <div className="flex gap-2">
          <div className="flex items-center gap-2 px-3 py-1 bg-success/10 text-success rounded-full text-sm font-medium animate-pulse">
            <span className="w-2 h-2 rounded-full bg-success"></span>
            LIVE System Active
          </div>
        </div>
      </div>

      {/* Stats Grid */}
      <motion.div
        variants={containerStats}
        initial="hidden"
        animate="show"
        className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-10"
      >
        <StatsCard
          title="Avg Temperature"
          value={`${sensors.temperature?.toFixed(1) || 0}°C`}
          icon={Thermometer}
          color="accent"
          trend={-2}
        />
        <StatsCard
          title="Humidity"
          value={`${sensors.humidity?.toFixed(1) || 0}%`}
          icon={Droplets}
          color="secondary"
          trend={5}
        />
        <StatsCard
          title="Lighting"
          value={`${sensors.lightLevel?.toFixed(0) || 0} lx`}
          icon={Sun}
          color="warning"
        />
        <StatsCard
          title="Occupancy"
          value={sensors.studentsPresent || 0}
          icon={Users}
          color="success"
          trend={10}
        />
      </motion.div>

      <div className="mb-10">
        <SensorChart />
      </div>

      {/* Quick Actions / Devices */}
      <h2 className="text-xl font-bold mb-4 flex items-center gap-2">
        <Grid className="w-5 h-5 text-primary" />
        Quick Device Control
      </h2>

      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        {Object.entries(devices).map(([id, device]) => {
          const Icon = getDeviceIcon(id);
          return (
            <motion.button
              key={id}
              whileHover={{ scale: 1.02 }}
              whileTap={{ scale: 0.98 }}
              onClick={() => toggleDevice(id, device.isOn)}
              className={`p-4 rounded-xl border transition-all flex items-center justify-between group ${device.isOn
                ? 'bg-primary/20 border-primary/50 text-white shadow-[0_0_15px_rgba(108,99,255,0.3)]'
                : 'bg-surface/50 border-white/5 text-gray-400 hover:bg-surface hover:border-white/10'
                }`}
            >
              <div className="flex items-center gap-4">
                <div className={`p-2 rounded-lg ${device.isOn ? 'bg-primary text-white' : 'bg-white/5 text-gray-500'}`}>
                  <Icon className={`w-5 h-5 ${id === 'ac' && device.isOn ? 'animate-spin-slow' : ''}`} />
                </div>
                <div className="text-left">
                  <h4 className="font-semibold capitalize text-sm">{id.replace('_', ' ')}</h4>
                  <p className="text-xs opacity-70">{device.isOn ? 'Active' : 'Off'}</p>
                </div>
              </div>

              <div className={`w-3 h-3 rounded-full ${device.isOn ? 'bg-success shadow-[0_0_8px_#00E676]' : 'bg-gray-700'}`} />
            </motion.button>
          );
        })}
      </div>

    </Layout>
  );
}
