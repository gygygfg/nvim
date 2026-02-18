# React useState Hook 完整指南

## 🎯 概述
`useState` 是 React 16.8 引入的 Hook，允许你在函数组件中添加和管理状态。

## 📋 基本语法
```javascript
import React, { useState } from 'react';

const [state, setState] = useState(initialState);
```

## 🚀 基础示例

### 计数器示例
```javascript
function Counter() {
  const [count, setCount] = useState(0);

  return (
    <div>
      <p>You clicked {count} times</p>
      <button onClick={() => setCount(count + 1)}>
        Click me
      </button>
    </div>
  );
}
```

### 表单输入示例
```javascript
function Form() {
  const [name, setName] = useState('');
  const [email, setEmail] = useState('');

  const handleSubmit = (e) => {
    e.preventDefault();
    console.log('Name:', name, 'Email:', email);
  };

  return (
    <form onSubmit={handleSubmit}>
      <input
        type="text"
        value={name}
        onChange={(e) => setName(e.target.value)}
        placeholder="Your name"
      />
      <input
        type="email"
        value={email}
        onChange={(e) => setEmail(e.target.value)}
        placeholder="Your email"
      />
      <button type="submit">Submit</button>
    </form>
  );
}
```

## 🔧 核心特性

### 1. 状态声明
```javascript
// 基本类型
const [count, setCount] = useState(0);
const [name, setName] = useState('John');
const [isActive, setIsActive] = useState(false);

// 对象类型
const [user, setUser] = useState({
  name: 'John',
  age: 30,
  email: 'john@example.com'
});

// 数组类型
const [items, setItems] = useState(['item1', 'item2', 'item3']);
```

### 2. 状态更新

#### 直接更新
```javascript
setCount(10);           // 数字
setName('Jane');        // 字符串
setIsActive(true);      // 布尔值
```

#### 函数式更新（推荐）
```javascript
setCount(prevCount => prevCount + 1);
setItems(prevItems => [...prevItems, 'newItem']);
```

### 3. 对象状态更新
```javascript
// 错误：直接修改
setUser({ age: 31 }); // ❌ 会丢失 name 和 email

// 正确：展开运算符
setUser(prevUser => ({
  ...prevUser,
  age: 31
}));

// 更新多个属性
setUser(prevUser => ({
  ...prevUser,
  name: 'Jane',
  age: 31
}));
```

### 4. 数组状态更新
```javascript
// 添加元素
setItems(prevItems => [...prevItems, 'newItem']);

// 删除元素
setItems(prevItems => prevItems.filter(item => item.id !== idToRemove));

// 更新元素
setItems(prevItems => prevItems.map(item => 
  item.id === idToUpdate ? { ...item, name: 'Updated' } : item
));
```

## 📝 实用示例

### 1. Toggle 开关
```javascript
function Toggle() {
  const [isOn, setIsOn] = useState(false);

  return (
    <div>
      <button onClick={() => setIsOn(!isOn)}>
        {isOn ? 'Turn OFF' : 'Turn ON'}
      </button>
      <p>Status: {isOn ? 'ON' : 'OFF'}</p>
    </div>
  );
}
```

### 2. 待办事项列表
```javascript
function TodoList() {
  const [todos, setTodos] = useState([]);
  const [inputValue, setInputValue] = useState('');

  const addTodo = () => {
    if (inputValue.trim()) {
      setTodos([...todos, {
        id: Date.now(),
        text: inputValue,
        completed: false
      }]);
      setInputValue('');
    }
  };

  const toggleTodo = (id) => {
    setTodos(todos.map(todo =>
      todo.id === id ? { ...todo, completed: !todo.completed } : todo
    ));
  };

  return (
    <div>
      <input
        value={inputValue}
        onChange={(e) => setInputValue(e.target.value)}
        placeholder="Add a todo"
      />
      <button onClick={addTodo}>Add</button>
      
      <ul>
        {todos.map(todo => (
          <li
            key={todo.id}
            style={{ textDecoration: todo.completed ? 'line-through' : 'none' }}
            onClick={() => toggleTodo(todo.id)}
          >
            {todo.text}
          </li>
        ))}
      </ul>
    </div>
  );
}
```

### 3. 自定义 Hook
```javascript
// 自定义 useLocalStorage Hook
function useLocalStorage(key, initialValue) {
  const [storedValue, setStoredValue] = useState(() => {
    try {
      const item = window.localStorage.getItem(key);
      return item ? JSON.parse(item) : initialValue;
    } catch (error) {
      console.error(error);
      return initialValue;
    }
  });

  const setValue = (value) => {
    try {
      const valueToStore = value instanceof Function ? value(storedValue) : value;
      setStoredValue(valueToStore);
      window.localStorage.setItem(key, JSON.stringify(valueToStore));
    } catch (error) {
      console.error(error);
    }
  };

  return [storedValue, setValue];
}

// 使用自定义 Hook
function ComponentWithLocalStorage() {
  const [name, setName] = useLocalStorage('name', 'John');

  return (
    <div>
      <input
        value={name}
        onChange={(e) => setName(e.target.value)}
        placeholder="Enter your name"
      />
      <p>Hello, {name}!</p>
    </div>
  );
}
```

## ⚠️ 重要规则

### Hook 规则
1. **只在最顶层使用 Hook**
   ```javascript
   // ✅ 正确
   function MyComponent() {
     const [count, setCount] = useState(0);
     const [name, setName] = useState('');
     
     // ...
   }

   // ❌ 错误
   function MyComponent() {
     if (condition) {
       const [count, setCount] = useState(0); // 在条件语句中
     }
     
     for (let i = 0; i < 10; i++) {
       const [item, setItem] = useState(''); // 在循环中
     }
   }
   ```

2. **只在 React 函数中调用 Hook**
   - ✅ React 函数组件
   - ✅ 自定义 Hook
   - ❌ 普通 JavaScript 函数
   - ❌ Class 组件

## 🎯 最佳实践

### 1. 使用有意义的变量名
```javascript
// ✅ 好
const [userName, setUserName] = useState('');
const [isLoading, setIsLoading] = useState(false);
const [productList, setProductList] = useState([]);

// ❌ 不好
const [a, setA] = useState('');
const [b, setB] = useState(false);
```

### 2. 复杂状态使用 useReducer
```javascript
// 当状态逻辑复杂时
const initialState = { count: 0 };

function reducer(state, action) {
  switch (action.type) {
    case 'increment':
      return { count: state.count + 1 };
    case 'decrement':
      return { count: state.count - 1 };
    default:
      throw new Error();
  }
}

function Counter() {
  const [state, dispatch] = useReducer(reducer, initialState);
  
  return (
    <>
      Count: {state.count}
      <button onClick={() => dispatch({ type: 'increment' })}>+</button>
      <button onClick={() => dispatch({ type: 'decrement' })}>-</button>
    </>
  );
}
```

### 3. 性能优化
```javascript
// 使用 useCallback 避免不必要的重新渲染
const memoizedCallback = useCallback(() => {
  doSomething(a, b);
}, [a, b]);

// 使用 useMemo 缓存计算结果
const memoizedValue = useMemo(() => computeExpensiveValue(a, b), [a, b]);
```

## 🔍 常见问题

### 1. 状态更新是异步的
```javascript
const [count, setCount] = useState(0);

const handleClick = () => {
  setCount(count + 1);
  console.log(count); // 仍然是旧值
  
  // 使用函数式更新获取最新值
  setCount(prevCount => {
    const newCount = prevCount + 1;
    console.log(newCount); // 新值
    return newCount;
  });
};
```

### 2. 初始化函数
```javascript
// 避免在每次渲染时都执行昂贵计算
const [state, setState] = useState(() => {
  const expensiveValue = computeExpensiveValue();
  return expensiveValue;
});
```

### 3. 批量更新
```javascript
// React 会自动批量更新
const handleClick = () => {
  setCount(count + 1);
  setName('Jane');
  setIsActive(true);
  // 只会触发一次重新渲染
};
```

## 📚 学习资源

### 官方文档
- [React 官方文档 - useState](https://reactjs.org/docs/hooks-state.html)
- [React Hooks API 参考](https://reactjs.org/docs/hooks-reference.html)

### 进阶学习
1. **React Hooks 完整指南**
2. **自定义 Hooks 模式**
3. **状态管理最佳实践**
4. **性能优化技巧**

### 工具和库
1. **React DevTools** - 调试 Hook
2. **ESLint Plugin React Hooks** - 强制执行 Hook 规则
3. **React Query** - 服务器状态管理
4. **Zustand** - 轻量级状态管理

## 🎓 总结

`useState` 是 React 函数组件的核心 Hook，它：
- ✅ 使函数组件拥有状态能力
- ✅ 提供简单直观的 API
- ✅ 支持各种数据类型
- ✅ 与 React 生态系统完美集成

掌握 `useState` 是学习 React Hooks 的第一步，也是构建现代 React 应用的基础。

---

*本文档通过 @{mcp_servers} 工具组调用 context7 服务器生成，提供 React useState Hook 的完整参考指南。*