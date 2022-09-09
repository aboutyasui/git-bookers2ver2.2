class ChatsController < ApplicationController
  before_action :reject_non_related, only: [:show]
  #以下のコメントは「AさんがBさんに対してチャットする」想定です。

  def show
    #BさんのUser情報を取得
    @user = User.find(params[:id])
    #user_roomsテーブルのuser_idがAさんのレコードのroom_idを配列で取得
    rooms = current_user.user_rooms.pluck(:room_id)
    #user_idがBさん(@user)で、room_idがAさんの属するroom_id（配列）となるuser_roomsテーブルのレコードを取得して、user_room変数に格納
    #これによって、AさんとBさんに共通のroom_idが存在していれば、その共通のroom_idとBさんのuser_idがuser_room変数に格納される（1レコード）。存在しなければ、nilになる。
    #つまりログイン中のユーザーの部屋情報を全て取得
    user_room = UserRoom.find_by(user_id: @user.id, room_id: rooms)
    #その中にチャットする相手とのルームがあるか確認

    #user_roomでルームを取得できなかった（AさんとBさんのチャットがまだ存在しない）場合の処理
    room = nil
    if user_room.nil?
     #roomのidを採番
     room = Room.new
     room.save
     #採番したroomのidを使って、user_roomのレコードを2人分（Aさん用、Ｂさん用）作る（＝AさんとBさんに共通のroom_idを作る）
     #Bさんの@user.idをuser_idとして、room.idをroom_idとして、UserRoomモデルのがラムに保存（1レコード）
     UserRoom.create(user_id: @user.id, room_id: room.id)
     #Aさんのcurrent_user.idをuser_idとして、room.idをroom_idとして、UserRoomモデルのカラムに保存（1レコード）
     UserRoom.create(user_id: current_user.id, room_id: room.id)
    else
     #user_roomに紐づくroomsテーブルのレコードをroomに格納
     room = user_room.room
    end

    #roomに紐づくchatsテーブルのレコードを@chatsに格納
    @chats = room.chats
    #form_withでチャットを送信する際に必要な空のインスタンス
    #ここでroom.idを@chatに代入しておかないと、form_withで記述するroom_idに値が渡らない
    @chat = Chat.new(room_id: room.id)
  end

  def create
    @chat = current_user.chats.new(chat_params)
    @chat.save
    #render :validater unless @chat.save#もし新規投稿が保存されなかった場合validater.js.erbを探します。
    redirect_to request.referer || root_path  #元のviewに戻る・・・失敗した場合はroot_pathへ
  end

  private

  def chat_params
    params.require(:chat).permit(:message, :room_id)
  end

  def reject_non_related
    user = User.find(params[:id])
    unless current_user.following?(user) && user.following?(current_user)
      redirect_to request.referer || root_path
    end
  end

end