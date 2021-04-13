import React, { useEffect, useState } from "react";
import type {
  Filter,
  Filters,
  FilterValue,
} from "../../../../../types/moviematch";
import { Select } from "../atoms/Select";

import { AutoSuggestInput } from "./AutoSuggestInput";
import { useAsyncEffect } from "../../hooks/useAsyncEffect";

import styles from "./FilterField.module.css";

interface FilterFieldProps {
  name: string;
  filters: Filters;
  onChange: (filter: Filter | null) => void;
  getSuggestions: (key: string) => Promise<FilterValue[]>;
}

export const FilterField = ({
  name,
  onChange,
  filters,
  getSuggestions,
}: FilterFieldProps) => {
  const [key, setKey] = useState<string>("");
  const [operator, setOperator] = useState<string>("=");
  const [value, setValue] = useState<FilterValue[]>([]);
  const [suggestions, setSuggestions] = useState<FilterValue[]>([]);

  useAsyncEffect(async () => {
    if (key !== "") {
      const suggestions = await getSuggestions(key);
      setSuggestions(suggestions);
    }
  }, [key]);

  useEffect(() => {
    if (key && operator && value) {
      onChange({ key, operator, value: value.map((_) => _.value) });
    } else {
      onChange(null);
    }
  }, [key, operator, value]);

  const filter = filters.filters.find((_) => _.key === key);

  return (
    <fieldset className={styles.filterField}>
      <Select
        name={"key" + "-" + name}
        value={key}
        options={filters.filters.reduce(
          (acc, filter) => ({ ...acc, [filter.key]: filter.title }),
          {},
        )}
        onChange={(e) => {
          setKey(e.target.value);
          setOperator("=");
          setValue([]);
        }}
      />
      {filter && (
        <>
          <Select
            name={"operator-" + name}
            value={operator}
            options={filters.filterTypes[filter.type]?.reduce(
              (acc, filterType) => ({
                ...acc,
                [filterType.key]: filterType.title,
              }),
              {},
            )}
            onChange={(e) => setOperator(e.target.value)}
          />
          {filter.type !== "boolean" && (
            <AutoSuggestInput
              inputName={`value-${name}`}
              items={suggestions}
              onChange={setValue}
              value={value}
            />
          )}
        </>
      )}
    </fieldset>
  );
};