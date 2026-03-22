/**
 * Type augmentation for bun:test — adds the vitest-compatible
 * `test(name, { timeout }, fn)` overload that Bun supports at runtime
 * but @types/bun doesn't declare.
 */
declare module 'bun:test' {
  interface TestOptions {
    timeout?: number;
    retry?: number;
    repeats?: number;
    todo?: boolean;
    skip?: boolean;
    if?: boolean;
  }

  interface Test {
    (name: string, fn: () => void | Promise<void>): void;
    (name: string, options: TestOptions, fn: () => void | Promise<void>): void;
    skip: (name: string, fn: () => void | Promise<void>) => void;
    todo: (name: string, fn?: () => void | Promise<void>) => void;
    only: (name: string, fn: () => void | Promise<void>) => void;
    each: (table: readonly any[]) => (name: string, fn: (...args: any[]) => void | Promise<void>) => void;
    if: (condition: boolean) => (name: string, fn: () => void | Promise<void>) => void;
    skipIf: (condition: boolean) => (name: string, fn: () => void | Promise<void>) => void;
    todoIf: (condition: boolean) => (name: string, fn: () => void | Promise<void>) => void;
  }

  export const test: Test;
  export const it: Test;

  export function describe(name: string, fn: () => void): void;
  export namespace describe {
    function skip(name: string, fn: () => void): void;
    function todo(name: string, fn?: () => void): void;
    function only(name: string, fn: () => void): void;
    function each(table: readonly any[]): (name: string, fn: (...args: any[]) => void) => void;
    function if_(condition: boolean): (name: string, fn: () => void) => void;
    function skipIf(condition: boolean): (name: string, fn: () => void) => void;
  }

  export function expect(value: any, message?: string): any;
  export function beforeAll(fn: () => void | Promise<void>): void;
  export function beforeEach(fn: () => void | Promise<void>): void;
  export function afterAll(fn: () => void | Promise<void>): void;
  export function afterEach(fn: () => void | Promise<void>): void;
  export function mock(fn?: (...args: any[]) => any): any;
  export function spyOn(obj: any, method: string): any;
  export function setSystemTime(time?: number | Date): void;
}
