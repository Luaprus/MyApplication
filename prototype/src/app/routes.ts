import { createBrowserRouter } from "react-router";
import Home from "./pages/Home";
import { AIAssistant } from "./pages/AIAssistant";
import { Profile } from "./pages/Profile";
import { Login } from "./pages/Login";
import { Layout } from "./components/Layout";

export const router = createBrowserRouter([
  {
    path: "/login",
    Component: Login,
  },
  {
    path: "/",
    Component: Layout,
    children: [
      {
        index: true,
        Component: Home,
      },
      {
        path: "ai",
        Component: AIAssistant,
      },
      {
        path: "profile",
        Component: Profile,
      },
    ],
  },
]);
