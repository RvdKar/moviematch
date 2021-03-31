import React from "react";

import "./Select.css";

interface SelectProps<Value extends string = string> {
  name: string;
  options: Record<Value, string>;
  value: Value;
  onChange?: (event: React.ChangeEvent<HTMLSelectElement>) => void;
  onBlur?: (event: React.FocusEvent<HTMLSelectElement>) => void;
}

export const Select = ({
  name,
  value = "",
  options,
  onChange,
  onBlur,
}: SelectProps) => (
  <div className="Select">
    <select
      className="Select_Element"
      name={name}
      onChange={onChange}
      onBlur={onBlur}
      value={value}
    >
      <option value="">&mdash; Select &mdash;</option>
      {options &&
        Object.entries(options).map(([optionValue, label]) => (
          <option
            value={optionValue}
            key={optionValue}
          >
            {label}
          </option>
        ))}
    </select>
  </div>
);
