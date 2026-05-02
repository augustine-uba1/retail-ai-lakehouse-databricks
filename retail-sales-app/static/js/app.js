console.log("Phase 4 app.js loaded - debug 2");

async function loadKpis() {
  console.log("Loading KPIs...");

  try {
    const response = await fetch("/api/kpis");
    const data = await response.json();

    console.log("KPI response:", data);

    document.getElementById("total-sales").textContent = data.total_sales;
    document.getElementById("orders").textContent = data.orders;
    document.getElementById("returns-rate").textContent = data.returns_rate;
    document.getElementById("low-stock-items").textContent = data.low_stock_items;
  } catch (error) {
    console.error("Failed to load KPIs:", error);

    document.getElementById("total-sales").textContent = "Error";
    document.getElementById("orders").textContent = "Error";
    document.getElementById("returns-rate").textContent = "Error";
    document.getElementById("low-stock-items").textContent = "Error";
  }
}

function addMessage(type, text) {
  const chatWindow = document.getElementById("chat-window");

  if (!chatWindow) {
    console.error("chat-window element was not found");
    return;
  }

  const message = document.createElement("div");
  message.className = `message ${type}`;
  message.textContent = text;

  chatWindow.appendChild(message);
  chatWindow.scrollTop = chatWindow.scrollHeight;
}

async function handleChatSubmit(event) {
  event.preventDefault();

  console.log("Chat form submitted");

  const input = document.getElementById("question-input");

  if (!input) {
    console.error("question-input element was not found");
    return;
  }

  const question = input.value.trim();

  if (!question) {
    return;
  }

  addMessage("user", question);
  input.value = "";

  addMessage("assistant", "Asking Databricks Genie...");

  try {
    const response = await fetch("/api/chat", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ question }),
    });

    const data = await response.json();

    console.log("Chat API response:", data);

    const chatWindow = document.getElementById("chat-window");
    const lastMessage = chatWindow.lastChild;

    if (!response.ok) {
      lastMessage.textContent =
        data.detail || "Something went wrong calling Genie.";
      return;
    }

    let responseText = data.answer || "No answer returned from Genie.";

    if (data.generated_sql) {
      responseText += "\n\nGenerated SQL:\n" + data.generated_sql;
    }

    lastMessage.textContent = responseText;
  } catch (error) {
    console.error("Error calling Genie:", error);
    addMessage("assistant", `Error calling Genie: ${error}`);
  }
}

document.addEventListener("DOMContentLoaded", () => {
  console.log("DOM fully loaded");

  loadKpis();

  const chatForm = document.getElementById("chat-form");

  if (!chatForm) {
    console.error("chat-form element was not found");
    return;
  }

  chatForm.addEventListener("submit", handleChatSubmit);

  console.log("Chat form event listener attached");
});