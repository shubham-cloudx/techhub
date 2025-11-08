import { Monitor, Cpu, HardDrive, MemoryStick, Zap, Box, Keyboard, Package } from 'lucide-react';

interface CategoryFilterProps {
  selectedCategory: string;
  onCategoryChange: (category: string) => void;
}

const categories = [
  { id: 'all', name: 'All Products', icon: Package },
  { id: 'monitors', name: 'Monitors', icon: Monitor },
  { id: 'graphics-cards', name: 'Graphics Cards', icon: Cpu },
  { id: 'processors', name: 'Processors', icon: Cpu },
  { id: 'memory', name: 'Memory', icon: MemoryStick },
  { id: 'storage', name: 'Storage', icon: HardDrive },
  { id: 'peripherals', name: 'Peripherals', icon: Keyboard },
  { id: 'power-supplies', name: 'Power Supplies', icon: Zap },
  { id: 'cases', name: 'Cases', icon: Box },
];

export function CategoryFilter({ selectedCategory, onCategoryChange }: CategoryFilterProps) {
  return (
    <div className="bg-white rounded-xl shadow-md p-6 mb-8">
      <h2 className="text-lg font-semibold text-gray-900 mb-4">Categories</h2>
      <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-9 gap-3">
        {categories.map((category) => {
          const Icon = category.icon;
          const isSelected = selectedCategory === category.id;

          return (
            <button
              key={category.id}
              onClick={() => onCategoryChange(category.id)}
              className={`flex flex-col items-center p-4 rounded-lg border-2 transition-all ${
                isSelected
                  ? 'border-blue-600 bg-blue-50 text-blue-600'
                  : 'border-gray-200 hover:border-gray-300 text-gray-700 hover:bg-gray-50'
              }`}
            >
              <Icon className="w-6 h-6 mb-2" />
              <span className="text-xs font-medium text-center">{category.name}</span>
            </button>
          );
        })}
      </div>
    </div>
  );
}
