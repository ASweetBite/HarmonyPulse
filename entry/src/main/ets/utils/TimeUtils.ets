// src/main/ets/utils/TimeUtils.ets

export function number2time(number: number): string {
  const m = Math.floor(number / 1000 / 60);
  const s = Math.floor(number / 1000 % 60);
  return `${m.toString().padStart(2, '0')}:${s.toString().padStart(2, '0')}`;
}
