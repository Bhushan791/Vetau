// components/StatsCard.jsx

import { motion } from 'framer-motion';
import { TrendingUp, TrendingDown } from 'lucide-react';

const StatsCard = ({
  icon: Icon,
  label,
  value,
  prefix = "",
  change,
  color = "blue",
  loading = false,
}) => {
  const VALID_COLORS = ["blue", "green", "purple", "orange", "pink", "indigo"];
  const safeColor = VALID_COLORS.includes(color) ? color : "blue";

  const colorClasses = {
    blue: "text-blue-500",
    green: "text-green-500",
    purple: "text-purple-500",
    orange: "text-orange-500",
    pink: "text-pink-500",
    indigo: "text-indigo-500",
  };

  const bgColorClasses = {
    blue: "bg-blue-50",
    green: "bg-green-50",
    purple: "bg-purple-50",
    orange: "bg-orange-50",
    pink: "bg-pink-50",
    indigo: "bg-indigo-50",
  };

  // CLEAN VALUE
  const displayValue = (() => {
    if (value === null || value === undefined) return 0;

    if (typeof value === "object") {
      if ("count" in value) return value.count;
      if ("value" in value) return value.value;
      return 0;
    }

    return value;
  })();

  // CLEAN CHANGE
  const displayChange = (() => {
    if (change === null || change === undefined) return null;

    if (typeof change === "object") {
      if ("growth" in change) return change.growth;
      if ("change" in change) return change.change;
      return null;
    }

    return change;
  })();

  const isIncrease = displayChange !== null && displayChange >= 0;

  if (loading) {
    return (
      <div className="bg-white rounded-xl shadow-sm border border-gray-100 p-6 animate-pulse">
        <div className="flex items-center justify-between">
          <div className="flex-1">
            <div className="h-4 bg-gray-200 rounded w-24 mb-3"></div>
            <div className="h-8 bg-gray-200 rounded w-32 mb-2"></div>
            <div className="h-3 bg-gray-200 rounded w-20"></div>
          </div>
          <div className="w-12 h-12 bg-gray-200 rounded-lg"></div>
        </div>
      </div>
    );
  }

  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.25 }}
      className="bg-white rounded-xl shadow-sm border border-gray-100 p-6 hover:shadow-md transition-all duration-200"
    >
      <div className="flex items-center justify-between">
        {/* LABEL + VALUE */}
        <div className="flex-1">
          <p className="text-sm font-medium text-gray-600 mb-1">{label}</p>

          <h3 className="text-3xl font-bold text-gray-900 mb-2">
            {prefix}
            {typeof displayValue === "number"
              ? displayValue.toLocaleString("en-IN")
              : displayValue}
          </h3>

          {displayChange !== null && (
            <div className="flex items-center gap-1">
              {isIncrease ? (
                <TrendingUp className="w-4 h-4 text-green-500" />
              ) : (
                <TrendingDown className="w-4 h-4 text-red-500" />
              )}

              <span
                className={`text-sm font-medium ${
                  isIncrease ? "text-green-600" : "text-red-600"
                }`}
              >
                {displayChange > 0 ? "+" : ""}
                {displayChange}%
              </span>

              <span className="text-xs text-gray-500 ml-1">
                vs last month
              </span>
            </div>
          )}
        </div>

        {/* ICON */}
        <div className={`${bgColorClasses[safeColor]} p-3 rounded-lg`}>
          {Icon && <Icon className={`w-6 h-6 ${colorClasses[safeColor]}`} />}
        </div>
      </div>
    </motion.div>
  );
};

export default StatsCard;
