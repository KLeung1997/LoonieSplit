import React, { useState, useRef, useEffect } from 'react';
import { Plus, Trash2, Users, Calculator, MapPin, UserPlus, X, Receipt, Copy, Eye, EyeOff, ChevronDown, Search } from 'lucide-react';

const PROVINCES = {
  AB: { name: 'Alberta', gst: 5, pst: 0, hst: 0 },
  BC: { name: 'British Columbia', gst: 5, pst: 7, hst: 0 },
  MB: { name: 'Manitoba', gst: 5, pst: 7, hst: 0 },
  NB: { name: 'New Brunswick', gst: 0, pst: 0, hst: 15 },
  NL: { name: 'Newfoundland', gst: 0, pst: 0, hst: 15 },
  NS: { name: 'Nova Scotia', gst: 0, pst: 0, hst: 15 },
  NT: { name: 'Northwest Territories', gst: 5, pst: 0, hst: 0 },
  NU: { name: 'Nunavut', gst: 5, pst: 0, hst: 0 },
  ON: { name: 'Ontario', gst: 0, pst: 0, hst: 13 },
  PE: { name: 'Prince Edward Island', gst: 0, pst: 0, hst: 15 },
  QC: { name: 'Quebec', gst: 5, pst: 9.975, hst: 0 },
  SK: { name: 'Saskatchewan', gst: 5, pst: 6, hst: 0 },
  YT: { name: 'Yukon', gst: 5, pst: 0, hst: 0 },
};

// All available additional taxes in Canada with province applicability
// provinces: ['ALL'] means federal/applies everywhere, otherwise specific province codes
const ADDITIONAL_TAXES = {
  none: { name: 'None', rate: 0, category: 'none', provinces: ['ALL'] },
  
  // Federal taxes (apply to all provinces)
  cannabisFed: { name: 'Cannabis Federal (10%)', rate: 10, category: 'cannabis', provinces: ['ALL'] },
  tobaccoFed: { name: 'Tobacco Federal (~15%)', rate: 15, category: 'tobacco', provinces: ['ALL'] },
  fuelFed: { name: 'Fuel Federal Excise (~10%)', rate: 10, category: 'fuel', provinces: ['ALL'] },
  vapingFed: { name: 'Vaping Federal (~12%)', rate: 12, category: 'vaping', provinces: ['ALL'] },
  tireRecycling: { name: 'Tire Recycling (~3%)', rate: 3, category: 'eco', provinces: ['ALL'] },
  electronicsRecycling: { name: 'Electronics Eco (~2%)', rate: 2, category: 'eco', provinces: ['ALL'] },
  
  // Alberta
  liquorAB: { name: 'AB Liquor Markup (~5%)', rate: 5, category: 'alcohol', provinces: ['AB'] },
  cannabisAB: { name: 'AB Cannabis (Fed+Prov 26.8%)', rate: 26.8, category: 'cannabis', provinces: ['AB'] },
  hotelAB: { name: 'AB Tourism Levy (4%)', rate: 4, category: 'accommodation', provinces: ['AB'] },
  hotelCalgary: { name: 'Calgary Hotel DMF (3%)', rate: 3, category: 'accommodation', provinces: ['AB'] },
  hotelEdmonton: { name: 'Edmonton Hotel DMF (5%)', rate: 5, category: 'accommodation', provinces: ['AB'] },
  
  // British Columbia
  liquorBC: { name: 'BC Liquor (10%)', rate: 10, category: 'alcohol', provinces: ['BC'] },
  cannabisBC: { name: 'BC Cannabis (Fed+Prov 30%)', rate: 30, category: 'cannabis', provinces: ['BC'] },
  tobaccoBC: { name: 'BC Tobacco (~25%)', rate: 25, category: 'tobacco', provinces: ['BC'] },
  hotelBC: { name: 'BC MRDT (up to 3%)', rate: 3, category: 'accommodation', provinces: ['BC'] },
  hotelVancouver: { name: 'Vancouver Hotel (8% + 3% MRDT)', rate: 11, category: 'accommodation', provinces: ['BC'] },
  hotelVictoria: { name: 'Victoria Hotel (8% + 2% MRDT)', rate: 10, category: 'accommodation', provinces: ['BC'] },
  hotelWhistler: { name: 'Whistler Hotel (8% + 3% MRDT)', rate: 11, category: 'accommodation', provinces: ['BC'] },
  fuelBC: { name: 'BC Fuel (Carbon+Prov ~18%)', rate: 18, category: 'fuel', provinces: ['BC'] },
  vapingBC: { name: 'BC Vaping (20%)', rate: 20, category: 'vaping', provinces: ['BC'] },
  
  // Manitoba
  liquorMB: { name: 'MB Liquor Markup (~7%)', rate: 7, category: 'alcohol', provinces: ['MB'] },
  hotelMB: { name: 'MB Accommodation (5%)', rate: 5, category: 'accommodation', provinces: ['MB'] },
  hotelWinnipeg: { name: 'Winnipeg Hotel (5% + 6% Dest)', rate: 11, category: 'accommodation', provinces: ['MB'] },
  ticketsMB: { name: 'MB Ticket Tax (10%)', rate: 10, category: 'entertainment', provinces: ['MB'] },
  
  // New Brunswick
  hotelNB: { name: 'NB Hotel Levy (varies)', rate: 2, category: 'accommodation', provinces: ['NB'] },
  
  // Newfoundland
  sugarTaxNL: { name: 'NL Sugar Drink (~5%)', rate: 5, category: 'beverage', provinces: ['NL'] },
  hotelNL: { name: 'NL Tourism Levy (4%)', rate: 4, category: 'accommodation', provinces: ['NL'] },
  
  // Nova Scotia
  liquorNS: { name: 'NS Liquor Markup (~5%)', rate: 5, category: 'alcohol', provinces: ['NS'] },
  hotelNS: { name: 'NS Marketing Levy (2%)', rate: 2, category: 'accommodation', provinces: ['NS'] },
  hotelHalifax: { name: 'Halifax Hotel (2% + 2% Dest)', rate: 4, category: 'accommodation', provinces: ['NS'] },
  
  // Ontario
  liquorON: { name: 'ON Beer/Wine Store (6.1%)', rate: 6.1, category: 'alcohol', provinces: ['ON'] },
  cannabisON: { name: 'ON Cannabis (Fed+Prov 13.9%)', rate: 13.9, category: 'cannabis', provinces: ['ON'] },
  tobaccoON: { name: 'ON Tobacco (~22%)', rate: 22, category: 'tobacco', provinces: ['ON'] },
  hotelON: { name: 'ON MAT (4%)', rate: 4, category: 'accommodation', provinces: ['ON'] },
  hotelToronto: { name: 'Toronto Hotel (4% + 2.5% Dest)', rate: 6.5, category: 'accommodation', provinces: ['ON'] },
  hotelOttawa: { name: 'Ottawa Hotel (4%)', rate: 4, category: 'accommodation', provinces: ['ON'] },
  hotelNiagara: { name: 'Niagara Falls Hotel (4% + 2%)', rate: 6, category: 'accommodation', provinces: ['ON'] },
  fuelON: { name: 'ON Fuel (~14%)', rate: 14, category: 'fuel', provinces: ['ON'] },
  vapingON: { name: 'ON Vaping (~18%)', rate: 18, category: 'vaping', provinces: ['ON'] },
  amusementON: { name: 'ON Amusement (10%)', rate: 10, category: 'entertainment', provinces: ['ON'] },
  insuranceON: { name: 'ON Insurance Premium (8%)', rate: 8, category: 'insurance', provinces: ['ON'] },
  
  // Prince Edward Island
  hotelPE: { name: 'PE Tourism Levy (3%)', rate: 3, category: 'accommodation', provinces: ['PE'] },
  
  // Quebec
  liquorQC: { name: 'QC Alcohol (~10%)', rate: 10, category: 'alcohol', provinces: ['QC'] },
  cannabisQC: { name: 'QC Cannabis (~20%)', rate: 20, category: 'cannabis', provinces: ['QC'] },
  tobaccoQC: { name: 'QC Tobacco (~20%)', rate: 20, category: 'tobacco', provinces: ['QC'] },
  hotelQC: { name: 'QC Lodging (3.5%)', rate: 3.5, category: 'accommodation', provinces: ['QC'] },
  hotelMontreal: { name: 'Montreal Hotel (3.5%)', rate: 3.5, category: 'accommodation', provinces: ['QC'] },
  hotelQuebecCity: { name: 'Quebec City Hotel (3.5%)', rate: 3.5, category: 'accommodation', provinces: ['QC'] },
  fuelQC: { name: 'QC Fuel (~19%)', rate: 19, category: 'fuel', provinces: ['QC'] },
  insuranceQC: { name: 'QC Insurance Premium (9%)', rate: 9, category: 'insurance', provinces: ['QC'] },
  
  // Saskatchewan
  liquorSK: { name: 'SK Liquor (10%)', rate: 10, category: 'alcohol', provinces: ['SK'] },
  hotelSK: { name: 'SK PST on Lodging (incl.)', rate: 0, category: 'accommodation', provinces: ['SK'] },
  hotelRegina: { name: 'Regina Hotel Levy (3%)', rate: 3, category: 'accommodation', provinces: ['SK'] },
  hotelSaskatoon: { name: 'Saskatoon Hotel Levy (4%)', rate: 4, category: 'accommodation', provinces: ['SK'] },
  
  // Territories
  hotelYT: { name: 'YT Hotel Tax (varies)', rate: 5, category: 'accommodation', provinces: ['YT'] },
  hotelNT: { name: 'NT Hotel Tax (varies)', rate: 4, category: 'accommodation', provinces: ['NT'] },
  hotelNU: { name: 'NU Hotel Tax (varies)', rate: 0, category: 'accommodation', provinces: ['NU'] },
};

// Group taxes by category for display
const TAX_CATEGORIES = {
  none: '⚪ Standard',
  alcohol: '🍺 Alcohol',
  cannabis: '🌿 Cannabis',
  tobacco: '🚬 Tobacco',
  beverage: '🥤 Beverage',
  accommodation: '🏨 Accommodation',
  fuel: '⛽ Fuel',
  vaping: '💨 Vaping',
  entertainment: '🎭 Entertainment',
  insurance: '📋 Insurance',
  eco: '♻️ Eco Fees',
};

const COLORS = [
  'bg-blue-500', 'bg-green-500', 'bg-purple-500', 'bg-orange-500', 
  'bg-pink-500', 'bg-teal-500', 'bg-indigo-500', 'bg-amber-500'
];

// Helper function to round to 2 decimal places
const round2 = (num) => Math.round(num * 100) / 100;

// Searchable Dropdown Component
function TaxCombobox({ value, customRate, onChange, onCustomRateChange, province }) {
  const [isOpen, setIsOpen] = useState(false);
  const [search, setSearch] = useState('');
  const [isCustomMode, setIsCustomMode] = useState(value === 'custom');
  const containerRef = useRef(null);
  const inputRef = useRef(null);

  // Close dropdown when clicking outside
  useEffect(() => {
    const handleClickOutside = (event) => {
      if (containerRef.current && !containerRef.current.contains(event.target)) {
        setIsOpen(false);
        setSearch('');
      }
    };
    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, []);

  // Reset to none if current selection doesn't apply to new province
  useEffect(() => {
    if (value !== 'none' && value !== 'custom') {
      const tax = ADDITIONAL_TAXES[value];
      if (tax && !tax.provinces.includes('ALL') && !tax.provinces.includes(province)) {
        onChange('none');
      }
    }
  }, [province, value, onChange]);

  // Filter taxes based on province and search
  const filteredTaxes = Object.entries(ADDITIONAL_TAXES).filter(([key, tax]) => {
    // Filter by province
    const appliesToProvince = tax.provinces.includes('ALL') || tax.provinces.includes(province);
    if (!appliesToProvince) return false;
    
    // Filter by search
    if (!search) return true;
    const searchLower = search.toLowerCase();
    return tax.name.toLowerCase().includes(searchLower) || 
           TAX_CATEGORIES[tax.category]?.toLowerCase().includes(searchLower);
  });

  // Group filtered taxes by category
  const groupedTaxes = filteredTaxes.reduce((acc, [key, tax]) => {
    const category = tax.category;
    if (!acc[category]) acc[category] = [];
    acc[category].push({ key, ...tax });
    return acc;
  }, {});

  const selectedTax = ADDITIONAL_TAXES[value];
  const displayValue = isCustomMode 
    ? `Custom: ${customRate || 0}%`
    : selectedTax?.name || 'None';

  const handleSelect = (key) => {
    onChange(key);
    setIsCustomMode(false);
    setIsOpen(false);
    setSearch('');
  };

  const handleCustomClick = () => {
    setIsCustomMode(true);
    setIsOpen(false);
    setSearch('');
    onChange('custom');
  };

  // Check if search looks like a number (for custom rate)
  const searchAsNumber = parseFloat(search);
  const isSearchNumeric = !isNaN(searchAsNumber) && search.trim() !== '';

  return (
    <div ref={containerRef} className="relative">
      <div 
        className="w-full p-3 border border-gray-200 rounded-lg focus-within:ring-2 focus-within:ring-red-500 focus-within:border-transparent flex items-center gap-2 cursor-pointer bg-white"
        onClick={() => {
          setIsOpen(!isOpen);
          if (!isOpen) {
            setTimeout(() => inputRef.current?.focus(), 0);
          }
        }}
      >
        <Search size={16} className="text-gray-400" />
        {isOpen ? (
          <input
            ref={inputRef}
            type="text"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            placeholder="Search or enter % rate..."
            className="flex-1 outline-none text-sm"
            onClick={(e) => e.stopPropagation()}
          />
        ) : (
          <span className="flex-1 text-sm text-gray-700">{displayValue}</span>
        )}
        <ChevronDown size={16} className={`text-gray-400 transition-transform ${isOpen ? 'rotate-180' : ''}`} />
      </div>

      {isOpen && (
        <div className="absolute z-50 w-full mt-1 bg-white border border-gray-200 rounded-lg shadow-lg max-h-64 overflow-y-auto">
          {/* Custom rate option when typing a number */}
          {isSearchNumeric && (
            <button
              onClick={() => {
                onCustomRateChange(search);
                onChange('custom');
                setIsCustomMode(true);
                setIsOpen(false);
                setSearch('');
              }}
              className="w-full px-3 py-2 text-left text-sm hover:bg-red-50 text-red-600 font-medium border-b"
            >
              ⚙️ Use custom rate: {search}%
            </button>
          )}

          {/* Grouped tax options */}
          {Object.entries(groupedTaxes).map(([category, taxes]) => (
            <div key={category}>
              <div className="px-3 py-1.5 text-xs font-semibold text-gray-500 bg-gray-50 sticky top-0">
                {TAX_CATEGORIES[category]}
              </div>
              {taxes.map((tax) => (
                <button
                  key={tax.key}
                  onClick={() => handleSelect(tax.key)}
                  className={`w-full px-3 py-2 text-left text-sm hover:bg-gray-50 ${
                    value === tax.key && !isCustomMode ? 'bg-red-50 text-red-600' : 'text-gray-700'
                  }`}
                >
                  {tax.name}
                </button>
              ))}
            </div>
          ))}

          {/* Custom option at bottom */}
          <div className="border-t">
            <button
              onClick={handleCustomClick}
              className={`w-full px-3 py-2 text-left text-sm hover:bg-gray-50 ${
                isCustomMode ? 'bg-red-50 text-red-600' : 'text-gray-700'
              }`}
            >
              ⚙️ Enter custom rate...
            </button>
          </div>

          {filteredTaxes.length === 0 && !isSearchNumeric && (
            <div className="px-3 py-4 text-sm text-gray-400 text-center">
              No matching taxes for {PROVINCES[province]?.name}. Try entering a number.
            </div>
          )}
        </div>
      )}

      {/* Custom rate input when in custom mode */}
      {isCustomMode && (
        <div className="flex gap-2 items-center mt-2">
          <span className="text-sm text-gray-600">Rate:</span>
          <input
            type="number"
            placeholder="Enter %"
            value={customRate}
            onChange={(e) => onCustomRateChange(e.target.value)}
            step="0.1"
            min="0"
            className="w-24 p-2 border border-red-300 bg-red-50 rounded-lg text-sm focus:ring-2 focus:ring-red-500 focus:border-transparent"
            autoFocus
          />
          <span className="text-sm text-gray-600">%</span>
          <button
            onClick={() => {
              setIsCustomMode(false);
              onChange('none');
              onCustomRateChange('');
            }}
            className="text-xs text-gray-500 hover:text-gray-700"
          >
            Clear
          </button>
        </div>
      )}
    </div>
  );
}

export default function BillCalculator() {
  const [province, setProvince] = useState('BC');
  const [people, setPeople] = useState([{ id: 1, name: 'Person 1', isDefault: true }]);
  const [items, setItems] = useState([]);
  const [newItem, setNewItem] = useState('');
  const [newPrice, setNewPrice] = useState('');
  const [newAssignment, setNewAssignment] = useState('shared');
  const [newPstExempt, setNewPstExempt] = useState(false);
  const [newAdditionalTax, setNewAdditionalTax] = useState('none');
  const [customTaxRate, setCustomTaxRate] = useState('');
  const [tipPercent, setTipPercent] = useState(0);
  const [customTip, setCustomTip] = useState('');
  const [tipAfterTax, setTipAfterTax] = useState(false);
  const [newPersonName, setNewPersonName] = useState('');
  const [hiddenPersons, setHiddenPersons] = useState({});

  const taxInfo = PROVINCES[province];
  const hasPST = taxInfo.pst > 0;
  const hasHST = taxInfo.hst > 0;

  // Get base tax label
  const getBaseTaxLabel = () => {
    if (hasHST) return `HST ${taxInfo.hst}%`;
    if (hasPST) return `GST ${taxInfo.gst}% + PST ${taxInfo.pst}%`;
    return `GST ${taxInfo.gst}%`;
  };

  // Get effective tip percent (custom or preset)
  const effectiveTipPercent = customTip !== '' ? parseFloat(customTip) || 0 : tipPercent;

  // Get effective additional tax rate
  const getAdditionalTaxRate = (taxKey, itemCustomRate) => {
    if (taxKey === 'custom') {
      return parseFloat(itemCustomRate) || 0;
    }
    return ADDITIONAL_TAXES[taxKey]?.rate || 0;
  };

  // Toggle person visibility
  const togglePersonHidden = (personId) => {
    setHiddenPersons(prev => ({
      ...prev,
      [personId]: !prev[personId]
    }));
  };

  // Add a person (or replace default Person 1)
  const addPerson = () => {
    const name = newPersonName.trim();
    if (!name) return;
    
    const defaultPerson = people.find(p => p.isDefault);
    if (defaultPerson && people.length === 1) {
      setPeople([{ id: defaultPerson.id, name, isDefault: false }]);
    } else {
      const newId = Date.now();
      setPeople([...people, { id: newId, name, isDefault: false }]);
    }
    setNewPersonName('');
  };

  const removePerson = (id) => {
    if (people.length <= 1) return;
    setPeople(people.filter(p => p.id !== id));
    setItems(items.map(item => 
      item.assignedTo === id ? { ...item, assignedTo: 'shared' } : item
    ));
    setHiddenPersons(prev => {
      const newState = { ...prev };
      delete newState[id];
      return newState;
    });
  };

  // Add item
  const addItem = () => {
    if (newItem.trim() && newPrice) {
      setItems([...items, { 
        id: Date.now(), 
        name: newItem.trim(), 
        price: round2(parseFloat(newPrice)),
        assignedTo: newAssignment,
        pstExempt: newPstExempt,
        additionalTax: newAdditionalTax,
        customTaxRate: newAdditionalTax === 'custom' ? customTaxRate : ''
      }]);
      setNewItem('');
      setNewPrice('');
    }
  };

  // Duplicate last item
  const duplicateLastItem = () => {
    if (items.length === 0) return;
    const lastItem = items[items.length - 1];
    setNewItem(lastItem.name);
    setNewPrice(lastItem.price.toString());
    setNewPstExempt(lastItem.pstExempt);
    setNewAdditionalTax(lastItem.additionalTax);
    if (lastItem.additionalTax === 'custom') {
      setCustomTaxRate(lastItem.customTaxRate);
    }
  };

  const removeItem = (id) => {
    setItems(items.filter(item => item.id !== id));
  };

  const handleKeyPress = (e) => {
    if (e.key === 'Enter') addItem();
  };

  // Handle tip preset selection
  const handleTipPreset = (percent) => {
    setTipPercent(percent);
    setCustomTip('');
  };

  // Handle custom tip input
  const handleCustomTip = (value) => {
    setCustomTip(value);
    setTipPercent(0);
  };

  // Calculate GST for a single item (rounded)
  const calculateItemGst = (item) => {
    if (hasHST) return 0;
    return round2(item.price * (taxInfo.gst / 100));
  };

  // Calculate PST for a single item (rounded)
  const calculateItemPst = (item) => {
    if (hasHST) return 0;
    if (item.pstExempt) return 0;
    return round2(item.price * (taxInfo.pst / 100));
  };

  // Calculate HST for a single item (rounded)
  const calculateItemHst = (item) => {
    if (!hasHST) return 0;
    return round2(item.price * (taxInfo.hst / 100));
  };

  // Calculate additional tax
  const calculateItemAdditionalTax = (item) => {
    const rate = getAdditionalTaxRate(item.additionalTax, item.customTaxRate);
    return round2(item.price * (rate / 100));
  };

  // Calculate total tax for a single item
  const calculateItemTax = (item) => {
    return round2(
      calculateItemGst(item) + 
      calculateItemPst(item) + 
      calculateItemHst(item) + 
      calculateItemAdditionalTax(item)
    );
  };

  // Calculate per person
  const calculatePersonTotal = (personId) => {
    let subtotal = 0;
    let tax = 0;
    
    items.filter(item => item.assignedTo === personId).forEach(item => {
      subtotal += item.price;
      tax += calculateItemTax(item);
    });
    
    const sharedItems = items.filter(item => item.assignedTo === 'shared');
    sharedItems.forEach(item => {
      subtotal += round2(item.price / people.length);
      tax += round2(calculateItemTax(item) / people.length);
    });
    
    const tipBase = tipAfterTax ? round2(subtotal + tax) : subtotal;
    const tip = round2(tipBase * (effectiveTipPercent / 100));
    
    return round2(subtotal + tax + tip);
  };

  // Calculate totals
  const subtotal = round2(items.reduce((sum, item) => sum + item.price, 0));
  const gstTotal = round2(items.reduce((sum, item) => sum + calculateItemGst(item), 0));
  const pstTotal = round2(items.reduce((sum, item) => sum + calculateItemPst(item), 0));
  const hstTotal = round2(items.reduce((sum, item) => sum + calculateItemHst(item), 0));
  const additionalTaxTotal = round2(items.reduce((sum, item) => sum + calculateItemAdditionalTax(item), 0));
  const totalTax = round2(gstTotal + pstTotal + hstTotal + additionalTaxTotal);
  const tipBase = tipAfterTax ? round2(subtotal + totalTax) : subtotal;
  const tipAmount = round2(tipBase * (effectiveTipPercent / 100));
  const grandTotal = round2(subtotal + totalTax + tipAmount);

  const getPersonColor = (index) => COLORS[index % COLORS.length];

  const getAssignmentLabel = (assignedTo) => {
    if (assignedTo === 'shared') return 'Shared';
    const person = people.find(p => p.id === assignedTo);
    return person ? person.name : 'Unknown';
  };

  const getItemTaxLabel = (item) => {
    const labels = [];
    if (item.pstExempt && hasPST) labels.push('No PST');
    if (item.additionalTax !== 'none') {
      if (item.additionalTax === 'custom') {
        labels.push(`+${item.customTaxRate}%`);
      } else {
        const taxData = ADDITIONAL_TAXES[item.additionalTax];
        if (taxData) labels.push(`+${taxData.rate}%`);
      }
    }
    return labels;
  };

  const visiblePeople = people.filter(p => !hiddenPersons[p.id]);
  const hiddenCount = people.length - visiblePeople.length;

  return (
    <div className="min-h-screen bg-gradient-to-br from-red-50 to-white p-4">
      <div className="max-w-lg mx-auto">
        <div className="text-center mb-6">
          <h1 className="text-2xl font-bold text-gray-800 flex items-center justify-center gap-2">
            <Calculator className="text-red-600" />
            Canada Bill Splitter
          </h1>
          <p className="text-gray-500 text-sm mt-1">With comprehensive tax support</p>
        </div>

        {/* Province Selection */}
        <div className="bg-white rounded-xl shadow-sm p-4 mb-4">
          <label className="flex items-center gap-2 text-sm font-medium text-gray-700 mb-2">
            <MapPin size={16} className="text-red-500" />
            Province/Territory
          </label>
          <select
            value={province}
            onChange={(e) => setProvince(e.target.value)}
            className="w-full p-3 border border-gray-200 rounded-lg focus:ring-2 focus:ring-red-500 focus:border-transparent"
          >
            {Object.entries(PROVINCES).map(([code, info]) => (
              <option key={code} value={code}>
                {info.name} ({info.hst > 0 ? `HST ${info.hst}%` : `GST ${info.gst}%${info.pst > 0 ? ` + PST ${info.pst}%` : ''}`})
              </option>
            ))}
          </select>
        </div>

        {/* People Management */}
        <div className="bg-white rounded-xl shadow-sm p-4 mb-4">
          <h2 className="font-semibold text-gray-800 mb-3 flex items-center gap-2">
            <Users size={18} className="text-red-500" />
            People ({people.length})
          </h2>
          <div className="flex flex-wrap gap-2 mb-3">
            {people.map((person, index) => (
              <div 
                key={person.id} 
                className={`flex items-center gap-1 px-3 py-1.5 rounded-full text-white text-sm ${getPersonColor(index)}`}
              >
                <span>{person.name}</span>
                {people.length > 1 && (
                  <button onClick={() => removePerson(person.id)} className="hover:bg-white/20 rounded-full p-0.5">
                    <X size={14} />
                  </button>
                )}
              </div>
            ))}
          </div>
          <div className="flex gap-2">
            <input
              type="text"
              placeholder={people.length === 1 && people[0].isDefault ? "Enter name to replace Person 1" : "Add person name"}
              value={newPersonName}
              onChange={(e) => setNewPersonName(e.target.value)}
              onKeyPress={(e) => e.key === 'Enter' && addPerson()}
              className="flex-1 p-2 border border-gray-200 rounded-lg text-sm focus:ring-2 focus:ring-red-500 focus:border-transparent"
            />
            <button
              onClick={addPerson}
              disabled={!newPersonName.trim()}
              className="px-3 py-2 bg-gray-100 text-gray-700 rounded-lg hover:bg-gray-200 transition-colors flex items-center gap-1 text-sm disabled:bg-gray-50 disabled:text-gray-400"
            >
              <UserPlus size={16} />
              {people.length === 1 && people[0].isDefault ? 'Set' : 'Add'}
            </button>
          </div>
        </div>

        {/* Add Item */}
        <div className="bg-white rounded-xl shadow-sm p-4 mb-4">
          <div className="flex items-center justify-between mb-3">
            <h2 className="font-semibold text-gray-800 flex items-center gap-2">
              <Receipt size={18} className="text-red-500" />
              Add Item
            </h2>
            {items.length > 0 && (
              <button
                onClick={duplicateLastItem}
                className="px-3 py-1.5 bg-gray-100 text-gray-600 rounded-lg hover:bg-gray-200 transition-colors flex items-center gap-1 text-sm"
              >
                <Copy size={14} />
                Duplicate Last
              </button>
            )}
          </div>
          <div className="space-y-3">
            <div className="flex gap-2">
              <input
                type="text"
                placeholder="Item name"
                value={newItem}
                onChange={(e) => setNewItem(e.target.value)}
                onKeyPress={handleKeyPress}
                className="flex-1 p-3 border border-gray-200 rounded-lg focus:ring-2 focus:ring-red-500 focus:border-transparent"
              />
              <input
                type="number"
                placeholder="Price"
                value={newPrice}
                onChange={(e) => setNewPrice(e.target.value)}
                onKeyPress={handleKeyPress}
                step="0.01"
                min="0"
                className="w-24 p-3 border border-gray-200 rounded-lg focus:ring-2 focus:ring-red-500 focus:border-transparent"
              />
            </div>
            
            {/* Base Tax Info */}
            <div className="p-2 bg-gray-50 rounded-lg text-sm text-gray-600">
              Base: {getBaseTaxLabel()}
            </div>

            {/* PST Exempt Toggle */}
            {hasPST && (
              <label className="flex items-center gap-2 p-3 bg-amber-50 border border-amber-200 rounded-lg cursor-pointer">
                <input
                  type="checkbox"
                  checked={newPstExempt}
                  onChange={(e) => setNewPstExempt(e.target.checked)}
                  className="w-4 h-4 text-amber-600 rounded focus:ring-amber-500"
                />
                <span className="text-sm text-amber-800">
                  PST Exempt (GST {taxInfo.gst}% only)
                </span>
              </label>
            )}
            
            {/* Additional Tax Selection */}
            <div>
              <label className="text-sm font-medium text-gray-700 mb-1 block">
                Additional Tax <span className="text-gray-400 font-normal">({PROVINCES[province].name})</span>
              </label>
              <TaxCombobox
                value={newAdditionalTax}
                customRate={customTaxRate}
                onChange={setNewAdditionalTax}
                onCustomRateChange={setCustomTaxRate}
                province={province}
              />
            </div>
            
            <div className="flex gap-2">
              <select
                value={newAssignment}
                onChange={(e) => setNewAssignment(e.target.value === 'shared' ? 'shared' : parseInt(e.target.value))}
                className="flex-1 p-3 border border-gray-200 rounded-lg focus:ring-2 focus:ring-red-500 focus:border-transparent"
              >
                <option value="shared">🔄 Shared (split equally)</option>
                {people.map((person) => (
                  <option key={person.id} value={person.id}>👤 {person.name}</option>
                ))}
              </select>
              <button
                onClick={addItem}
                disabled={!newItem.trim() || !newPrice}
                className="px-4 py-3 bg-red-600 text-white rounded-lg hover:bg-red-700 transition-colors disabled:bg-gray-300 disabled:cursor-not-allowed"
              >
                <Plus size={20} />
              </button>
            </div>
          </div>
        </div>

        {/* Items List */}
        {items.length > 0 && (
          <div className="bg-white rounded-xl shadow-sm p-4 mb-4">
            <h2 className="font-semibold text-gray-800 mb-3">Items ({items.length})</h2>
            <div className="space-y-2 max-h-64 overflow-y-auto">
              {items.map((item) => {
                const personIndex = people.findIndex(p => p.id === item.assignedTo);
                const isShared = item.assignedTo === 'shared';
                const taxLabels = getItemTaxLabel(item);
                
                return (
                  <div key={item.id} className="flex items-center justify-between p-2 bg-gray-50 rounded-lg">
                    <div className="flex items-center gap-2 flex-wrap">
                      <span className={`px-2 py-0.5 rounded text-xs text-white ${isShared ? 'bg-gray-400' : getPersonColor(personIndex)}`}>
                        {isShared ? '🔄' : '👤'} {getAssignmentLabel(item.assignedTo)}
                      </span>
                      {taxLabels.map((label, i) => (
                        <span key={i} className="px-2 py-0.5 rounded text-xs bg-amber-100 text-amber-700">
                          {label}
                        </span>
                      ))}
                      <span className="text-gray-700">{item.name}</span>
                    </div>
                    <div className="flex items-center gap-2">
                      <span className="font-medium text-gray-800">${item.price.toFixed(2)}</span>
                      <button
                        onClick={() => removeItem(item.id)}
                        className="p-1 text-red-500 hover:bg-red-100 rounded transition-colors"
                      >
                        <Trash2 size={16} />
                      </button>
                    </div>
                  </div>
                );
              })}
            </div>
          </div>
        )}

        {/* Tip Option */}
        <div className="bg-white rounded-xl shadow-sm p-4 mb-4">
          <label className="text-sm font-medium text-gray-700 mb-2 block">Tip</label>
          
          <div className="flex gap-2 mb-3 flex-wrap">
            {[0, 10, 15, 18, 20, 25].map((percent) => (
              <button
                key={percent}
                onClick={() => handleTipPreset(percent)}
                className={`px-3 py-2 rounded-lg text-sm font-medium transition-colors ${
                  tipPercent === percent && customTip === ''
                    ? 'bg-red-600 text-white'
                    : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
                }`}
              >
                {percent === 0 ? 'No tip' : `${percent}%`}
              </button>
            ))}
          </div>
          
          <div className="flex gap-2 items-center mb-3">
            <span className="text-sm text-gray-600">Custom:</span>
            <input
              type="number"
              placeholder="Enter %"
              value={customTip}
              onChange={(e) => handleCustomTip(e.target.value)}
              step="0.1"
              min="0"
              className={`w-24 p-2 border rounded-lg text-sm focus:ring-2 focus:ring-red-500 focus:border-transparent ${
                customTip !== '' ? 'border-red-500 bg-red-50' : 'border-gray-200'
              }`}
            />
            <span className="text-sm text-gray-600">%</span>
            {customTip !== '' && (
              <button
                onClick={() => setCustomTip('')}
                className="text-xs text-gray-500 hover:text-gray-700"
              >
                Clear
              </button>
            )}
          </div>
          
          {effectiveTipPercent > 0 && (
            <div className="flex gap-2">
              <button
                onClick={() => setTipAfterTax(false)}
                className={`flex-1 py-2 px-3 rounded-lg text-sm font-medium transition-colors ${
                  !tipAfterTax 
                    ? 'bg-red-600 text-white' 
                    : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
                }`}
              >
                Before Tax
              </button>
              <button
                onClick={() => setTipAfterTax(true)}
                className={`flex-1 py-2 px-3 rounded-lg text-sm font-medium transition-colors ${
                  tipAfterTax 
                    ? 'bg-red-600 text-white' 
                    : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
                }`}
              >
                After Tax
              </button>
            </div>
          )}
        </div>

        {/* Summary */}
        <div className="bg-white rounded-xl shadow-sm p-4 mb-4">
          <h2 className="font-semibold text-gray-800 mb-3">Bill Summary</h2>
          <div className="space-y-2 text-sm">
            <div className="flex justify-between text-gray-600">
              <span>Subtotal</span>
              <span>${subtotal.toFixed(2)}</span>
            </div>
            
            {hasHST ? (
              <div className="flex justify-between text-gray-600">
                <span>HST ({taxInfo.hst}%)</span>
                <span>${hstTotal.toFixed(2)}</span>
              </div>
            ) : (
              <>
                <div className="flex justify-between text-gray-600">
                  <span>GST ({taxInfo.gst}%)</span>
                  <span>${gstTotal.toFixed(2)}</span>
                </div>
                {taxInfo.pst > 0 && (
                  <div className="flex justify-between text-gray-600">
                    <span>PST ({taxInfo.pst}%)</span>
                    <span>${pstTotal.toFixed(2)}</span>
                  </div>
                )}
              </>
            )}
            
            {additionalTaxTotal > 0 && (
              <div className="flex justify-between text-gray-600">
                <span>Additional Taxes</span>
                <span>${additionalTaxTotal.toFixed(2)}</span>
              </div>
            )}
            
            {effectiveTipPercent > 0 && (
              <div className="flex justify-between text-gray-600">
                <span>
                  Tip ({effectiveTipPercent}% {tipAfterTax ? 'after tax' : 'before tax'})
                </span>
                <span>${tipAmount.toFixed(2)}</span>
              </div>
            )}
            <div className="border-t pt-2 mt-2">
              <div className="flex justify-between font-semibold text-gray-800">
                <span>Grand Total</span>
                <span>${grandTotal.toFixed(2)}</span>
              </div>
            </div>
          </div>
        </div>

        {/* Per Person Breakdown */}
        <div className="bg-white rounded-xl shadow-sm p-4">
          <div className="flex items-center justify-between mb-4">
            <h2 className="font-semibold text-gray-800">Each Person Pays</h2>
            {hiddenCount > 0 && (
              <span className="text-xs text-gray-500">{hiddenCount} hidden</span>
            )}
          </div>
          
          <div className="flex flex-wrap gap-2 mb-4">
            {people.map((person, index) => {
              const isHidden = hiddenPersons[person.id];
              return (
                <button
                  key={person.id}
                  onClick={() => togglePersonHidden(person.id)}
                  className={`flex items-center gap-1 px-2 py-1 rounded-lg text-xs transition-colors ${
                    isHidden 
                      ? 'bg-gray-100 text-gray-400' 
                      : `${getPersonColor(index)} text-white`
                  }`}
                >
                  {isHidden ? <EyeOff size={12} /> : <Eye size={12} />}
                  <span>{person.name}</span>
                </button>
              );
            })}
          </div>

          <div className="space-y-3">
            {people.map((person, index) => {
              if (hiddenPersons[person.id]) return null;
              
              const personTotal = calculatePersonTotal(person.id);
              const personalItems = items.filter(item => item.assignedTo === person.id);
              const sharedItems = items.filter(item => item.assignedTo === 'shared');
              const personalSubtotal = round2(personalItems.reduce((sum, item) => sum + item.price, 0));
              const sharedSubtotal = round2(sharedItems.reduce((sum, item) => sum + item.price, 0) / people.length);
              
              return (
                <div key={person.id} className={`p-4 rounded-xl text-white ${getPersonColor(index)}`}>
                  <div className="flex justify-between items-center mb-2">
                    <span className="font-medium">{person.name}</span>
                    <span className="text-2xl font-bold">${personTotal.toFixed(2)}</span>
                  </div>
                  {(personalSubtotal > 0 || sharedSubtotal > 0) && (
                    <div className="text-xs opacity-80 space-y-0.5">
                      {personalSubtotal > 0 && (
                        <div>Personal: ${personalSubtotal.toFixed(2)}</div>
                      )}
                      {sharedSubtotal > 0 && (
                        <div>Shared ÷ {people.length}: ${sharedSubtotal.toFixed(2)}</div>
                      )}
                      <div>+ Tax & Tip</div>
                    </div>
                  )}
                </div>
              );
            })}
          </div>
          
          {visiblePeople.length === 0 && (
            <div className="text-center text-gray-400 py-4">
              All people are hidden. Click the buttons above to show.
            </div>
          )}
        </div>

        <div className="mt-4 text-center text-xs text-gray-400">
          🍁 Tax rates are estimates and may vary by municipality
        </div>
      </div>
    </div>
  );
}
