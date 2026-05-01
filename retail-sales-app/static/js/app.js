async function loadKpis() {
  const response = await fetch("/api/kpis");
  const data = await response.json();

  document.getElementById("total-sales").textContent = data.total_sales;
  document.getElementById("orders").textContent = data.orders;
  document.getElementById("returns-rate").textContent = data.returns_rate;
  document.getElementById("low-stock-items").textContent = data.low_stock_items;
}

function addMessage(type, text) {
  const chatWindow = document.getElementById("chat-window");
  const message = document.createElement("div");

  message.className = `message ${type}`;
  message.textContent = text;

  chatWindow.appendChild(message);
  chatWindow.scrollTop = chatWindow.scrollHeight;
}

async function handleChatSubmit(event) {
  event.preventDefault();

  const input = document.getElementById("question-input");
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
    addMessage("assistant", `Error calling Genie: ${error}`);
  }
}

document.addEventListener("DOMContentLoaded", () => {
  loadKpis();

  const chatForm = document.getElementById("chat-form");

  if (!chatForm) {
    console.error("chat-form element was not found");
    return;
  }

  chatForm.addEventListener("submit", handleChatSubmit);
});